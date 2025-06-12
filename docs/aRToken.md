# aRToken Contract Documentation

**Title:** aRToken
**Notice:** Implementation of a generic token
**Dev:** Extends ERC20 with Permit, Burnable, and AccessControlDefaultAdminRules functionalities

## Inheritance

- `@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol`
- `@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol`
- `@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol`

## Constants

### `MINTER_ROLE`

```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```

**Notice:** Role identifier for addresses authorized to mint tokens.

### `BURNER_ROLE`

```solidity
bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
```

**Notice:** Role identifier for addresses authorized to burn tokens.


## State Variables

### `_decimals`

```solidity
uint8 private _decimals;
```

**Description:** Stores the number of decimals for the token.

## Functions

### `constructor`

```solidity
constructor(
    address initialAdmin,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address minter,
    address burner,
    uint48 adminTransferDelay
) ERC20(name_, symbol_) ERC20Permit(name_) AccessControlDefaultAdminRules(adminTransferDelay, initialAdmin);
```

**Notice:** Contract constructor. Initializes the token name, symbol, decimals, permit mechanism, and access control roles.

**Parameters:**
- `initialAdmin`: The address that will be the initial admin with DEFAULT_ADMIN_ROLE.
- `name_`: The name of the token.
- `symbol_`: The symbol of the token.
- `decimals_`: The number of decimals for the token.
- `minter`: The address authorized to mint tokens (granted MINTER_ROLE).
- `burner`: The address authorized to burn tokens (granted BURNER_ROLE).
- `adminTransferDelay`: The delay (in seconds) for admin role transfers.

**Requirements:**
- `minter` cannot be the zero address.
- `burner` cannot be the zero address.

**Grants:**
- Grants MINTER_ROLE to the `minter` address.
- Grants BURNER_ROLE to the `burner` address.
- Grants DEFAULT_ADMIN_ROLE to the `initialAdmin` address (via AccessControlDefaultAdminRules).

### `decimals`

```solidity
function decimals() public view override returns (uint8);
```

**Notice:** Get the number of decimals for the token.
**Dev:** Overrides the standard ERC20 decimals function to return the custom decimal value.

**Returns:**
- `uint8`: The number of decimals.

### `mint`

```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE);
```

**Notice:** Mint new tokens. Only accounts with MINTER_ROLE can call this function.

**Parameters:**
- `to`: The address to mint tokens to. Must not be the zero address.
- `amount`: The amount of tokens to mint. Must be positive.

**Requirements:**
- Caller must have MINTER_ROLE.
- `to` cannot be the zero address.
- `amount` must be greater than 0.

### `burn`

```solidity
function burn(uint256 amount) public override(ERC20Burnable) onlyRole(BURNER_ROLE);
```

**Notice:** Implementation of the burn function from ERC20Burnable. Destroys a specified amount of tokens from the caller's balance. Only accounts with BURNER_ROLE can call this function.

**Parameters:**
- `amount`: The amount of tokens to burn.

**Requirements:**
- Caller must have BURNER_ROLE.
- Caller must have a balance of at least `amount`.

### `burnFrom`

```solidity
function burnFrom(
    address account,
    uint256 amount
) public override(ERC20Burnable) onlyRole(BURNER_ROLE);
```

**Notice:** Implementation of the burnFrom function from ERC20Burnable. Destroys a specified amount of tokens from a specific account, provided the caller has allowance. Only accounts with BURNER_ROLE can call this function.

**Parameters:**
- `account`: The account to burn tokens from.
- `amount`: The amount of tokens to burn.

**Requirements:**
- Caller must have BURNER_ROLE.
- `account` must have a balance of at least `amount`.
- Caller must have an allowance of at least `amount` from `account`.


## Access Control Summary

The contract uses role-based access control:

- **DEFAULT_ADMIN_ROLE**: Can manage all roles
- **MINTER_ROLE**: Can mint new tokens
- **BURNER_ROLE**: Can burn tokens

The default admin role has a transfer delay mechanism for security, requiring a two-step process with a time delay for admin transfers.