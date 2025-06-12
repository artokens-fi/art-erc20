pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {aRToken} from "../src/aRToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract aRTokenTest is Test {
    aRToken public token;

    address public constant OWNER = address(1);
    address public constant MINTER = address(2);
    address public constant BURNER = address(3);
    address public constant USER = address(4);
    uint48 public constant ADMIN_TRANSFER_DELAY = 1 days;

    // Token configuration
    string public constant TOKEN_NAME = "Test Reserve Token";
    string public constant TOKEN_SYMBOL = "TRT";
    uint8 public constant TOKEN_DECIMALS = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        vm.startPrank(OWNER);

        // Deploy token contract
        token = new aRToken(
            OWNER,
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            MINTER,
            BURNER,
            ADMIN_TRANSFER_DELAY
        );

        vm.stopPrank();
    }

    function test_InitialState() public {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), TOKEN_DECIMALS);

        // Check role assignments
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), OWNER));
        assertTrue(token.hasRole(token.MINTER_ROLE(), MINTER));
        assertTrue(token.hasRole(token.BURNER_ROLE(), BURNER));
    }

    function test_Mint() public {
        uint256 mintAmount = 1000e18;

        vm.startPrank(MINTER);
        token.mint(USER, mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(USER), mintAmount);
        assertEq(token.totalSupply(), mintAmount);
    }

    function test_BurnTokens() public {
        uint256 mintAmount = 1000e18;
        uint256 burnAmount = 500e18;

        // First mint tokens to BURNER
        vm.prank(MINTER);
        token.mint(BURNER, mintAmount);

        vm.startPrank(BURNER);
        // Expect the Transfer event from the burn
        vm.expectEmit(true, true, true, true);
        emit Transfer(BURNER, address(0), burnAmount);

        // Burn tokens
        token.burn(burnAmount);
        vm.stopPrank();

        assertEq(token.totalSupply(), mintAmount - burnAmount);
        assertEq(token.balanceOf(BURNER), mintAmount - burnAmount);
    }

    function test_OnlyMinterCanMint() public {
        vm.startPrank(USER);
        vm.expectRevert();
        token.mint(USER, 1000e18);
        vm.stopPrank();
    }

    function test_OnlyBurnerCanBurn() public {
        vm.startPrank(USER);
        vm.expectRevert();
        token.burn(1000e18);
        vm.stopPrank();
    }

    function test_Transfer() public {
        uint256 mintAmount = 1000e18;
        uint256 transferAmount = 500e18;
        address recipient = address(5);

        // First mint some tokens to the USER
        vm.prank(MINTER);
        token.mint(USER, mintAmount);

        // Perform transfer
        vm.startPrank(USER);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER, recipient, transferAmount);
        token.transfer(recipient, transferAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(USER), mintAmount - transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
    }

    function test_TransferFailsWithInsufficientBalance() public {
        uint256 mintAmount = 1000e18;
        uint256 transferAmount = 2000e18; // More than minted

        // First mint some tokens to the USER
        vm.prank(MINTER);
        token.mint(USER, mintAmount);

        // Attempt transfer
        vm.startPrank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                USER,
                mintAmount,
                transferAmount
            )
        );
        token.transfer(address(5), transferAmount);
        vm.stopPrank();
    }

    function test_ApproveAndTransferFrom() public {
        uint256 mintAmount = 1000e18;
        uint256 approveAmount = 500e18;
        uint256 transferAmount = 300e18;
        address spender = address(5);
        address recipient = address(6);

        // Get initial balances
        uint256 initialUserBalance = token.balanceOf(USER);
        uint256 initialRecipientBalance = token.balanceOf(recipient);

        // First mint some tokens to the USER
        vm.prank(MINTER);
        token.mint(USER, mintAmount);

        // Approve spending
        vm.startPrank(USER);
        token.approve(spender, approveAmount);
        assertEq(token.allowance(USER, spender), approveAmount);

        vm.stopPrank();

        // Transfer using approved allowance
        vm.startPrank(spender);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER, recipient, transferAmount);
        token.transferFrom(USER, recipient, transferAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(USER),
            initialUserBalance + mintAmount - transferAmount
        );
        assertEq(
            token.balanceOf(recipient),
            initialRecipientBalance + transferAmount
        );
        assertEq(
            token.allowance(USER, spender),
            approveAmount - transferAmount
        );
    }

    function test_TransferFromFailsWithInsufficientAllowance() public {
        uint256 mintAmount = 1000e18;
        uint256 approveAmount = 300e18;
        uint256 transferAmount = 500e18; // More than approved
        address spender = address(5);
        address recipient = address(6);

        // First mint some tokens to the USER
        vm.prank(MINTER);
        token.mint(USER, mintAmount);

        // Approve spending
        vm.startPrank(USER);
        token.approve(spender, approveAmount);
        vm.stopPrank();

        // Attempt transfer with insufficient allowance
        vm.startPrank(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                spender,
                approveAmount,
                transferAmount
            )
        );
        token.transferFrom(USER, recipient, transferAmount);
        vm.stopPrank();
    }

    function test_AdminCanGrantMinterRole() public {
        address newMinter = address(5);

        vm.startPrank(OWNER);
        token.grantRole(token.MINTER_ROLE(), newMinter);
        vm.stopPrank();

        assertTrue(token.hasRole(token.MINTER_ROLE(), newMinter));

        // Test that new minter can mint
        vm.prank(newMinter);
        token.mint(USER, 1000e18);

        assertEq(token.balanceOf(USER), 1000e18);
    }

    function test_AdminCanGrantBurnerRole() public {
        address newBurner = address(6);

        // First mint some tokens
        vm.prank(MINTER);
        token.mint(newBurner, 1000e18);

        vm.startPrank(OWNER);
        token.grantRole(token.BURNER_ROLE(), newBurner);
        vm.stopPrank();

        assertTrue(token.hasRole(token.BURNER_ROLE(), newBurner));

        // Test that new burner can burn
        vm.prank(newBurner);
        token.burn(500e18);

        assertEq(token.balanceOf(newBurner), 500e18);
    }

    function test_AdminCanRevokeRoles() public {
        vm.startPrank(OWNER);
        token.revokeRole(token.MINTER_ROLE(), MINTER);
        vm.stopPrank();

        assertFalse(token.hasRole(token.MINTER_ROLE(), MINTER));

        // Test that revoked minter cannot mint
        vm.startPrank(MINTER);
        vm.expectRevert();
        token.mint(USER, 1000e18);
        vm.stopPrank();
    }

    function test_NonAdminCannotGrantRoles() public {
        address newMinter = address(7);
        bytes32 minterRole = token.MINTER_ROLE();

        // Verify USER does not have admin role
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), USER));

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                USER,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        vm.prank(USER);
        token.grantRole(minterRole, newMinter);

        // Verify newMinter does not have the role
        assertFalse(token.hasRole(minterRole, newMinter));
    }
}
