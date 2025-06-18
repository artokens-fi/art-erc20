/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2025 ARTokens GmbH
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

/**
 * @title aRToken
 * @notice Implementation of a generic token
 * @dev Extends ERC20 with Permit, Burnable, and AccessControl functionalities
 */
contract aRToken is
    ERC20,
    ERC20Permit,
    ERC20Burnable,
    AccessControlDefaultAdminRules
{
    /// @notice Role for the minter
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role for the burner
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Minimum admin transfer delay to prevent immediate transfers
    uint48 public constant MIN_DELAY = 1 days; // Finding 3: Fixed - added MIN_DELAY constant

    // Custom errors for Finding 2
    error AccountAlreadyHasBurnerRole(address account);
    error AccountAlreadyHasMinterRole(address account);

    // Decimals for the token
    uint8 private _decimals;

    /**
     * @notice Contract constructor
     * @param initialAdmin The address that will be the initial admin
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param decimals_ The number of decimals for the token
     * @param minter The address authorized to mint tokens
     * @param burner The address authorized to burn tokens
     * @param adminTransferDelay The delay for admin transfers
     */
    constructor(
        address initialAdmin,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address minter,
        address burner,
        uint48 adminTransferDelay
    )
        ERC20(name_, symbol_)
        ERC20Permit(name_)
        AccessControlDefaultAdminRules(adminTransferDelay, initialAdmin)
    {
        require(minter != address(0), "Minter cannot be zero address");
        require(burner != address(0), "Burner cannot be zero address");
        require(
            minter != burner,
            "Minter and burner must be different addresses"
        );
        require(
            adminTransferDelay >= MIN_DELAY,
            "Admin transfer delay must be at least MIN_DELAY"
        );
        require(decimals_ > 0, "Decimals must be greater than zero");

        _grantRole(MINTER_ROLE, minter);
        _grantRole(BURNER_ROLE, burner);

        // Set decimals
        _decimals = decimals_;
    }

    /**
     * @notice Get the number of decimals for the token
     * @return The number of decimals
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mint new tokens
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be positive");

        _mint(to, amount);
    }

    /**
     * @notice Implementation of the burn function from ERC20Burnable
     * @param amount The amount of tokens to burn
     */
    function burn(
        uint256 amount
    ) public override(ERC20Burnable) onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    /**
     * @notice Implementation of the burnFrom function from ERC20Burnable
     * @param account The account to burn tokens from
     * @param amount The amount of tokens to burn
     * @dev INFO: This function uses the same allowance mechanism as transferFrom.
     * Any tokens approved to the BURNER_ROLE address can be burned.
     * Users should only approve the exact amount they intend to be burned.
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public override(ERC20Burnable) onlyRole(BURNER_ROLE) {
        super.burnFrom(account, amount);
    }

    /**
     * @notice Override grantRole to prevent same address having both MINTER and BURNER roles
     * @param role The role to grant
     * @param account The account to grant the role to
     * @dev Finding 2: Enhanced - prevent same address having both roles even after deployment
     */
    function grantRole(
        bytes32 role,
        address account
    ) public virtual override {
        // Check if granting MINTER_ROLE to an address that already has BURNER_ROLE
        if (role == MINTER_ROLE && hasRole(BURNER_ROLE, account)) {
            revert AccountAlreadyHasBurnerRole(account);
        }
        // Check if granting BURNER_ROLE to an address that already has MINTER_ROLE
        if (role == BURNER_ROLE && hasRole(MINTER_ROLE, account)) {
            revert AccountAlreadyHasMinterRole(account);
        }
        super.grantRole(role, account);
    }
}
