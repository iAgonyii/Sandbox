// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

    error InvalidStatus();
    error MintedOut();
    error OverLimitPerWallet();
    error WrongPrice();
    error OverLimitPerTx();

/// @title Template / testing contract for ERC721A
/// @author @0xAgony
contract SampleERC721A is ERC721A, Ownable {
    using Strings for uint256;

    /* MINT DETAILS */
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxAmountPerTx;
    uint256 public limitPerWallet;

    /* STATUS */
    enum Status {
        Closed,
        Public
    }

    Status public status = Status.Closed;

    constructor(
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxAmountPerTx,
        uint256 _limitPerWallet
    ) ERC721A("Test", "TEST") {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxAmountPerTx = _maxAmountPerTx;
        limitPerWallet = _limitPerWallet;
    }

    // =========================================================================
    //                       Minting Compliance Modifiers
    // =========================================================================

    modifier mintCompliance(uint256 _mintAmount, Status _status) {
        if (status != _status) revert InvalidStatus();
        if (_totalMinted() + _mintAmount > maxSupply) revert MintedOut();
        if (_numberMinted(msg.sender) + _mintAmount > limitPerWallet)
            revert OverLimitPerWallet();
        if (msg.value != _mintAmount * mintPrice) revert WrongPrice();
        if (_mintAmount > maxAmountPerTx) revert OverLimitPerTx();
        _;
    }

    modifier ownerMintCompliance(uint256 _mintAmount) {
        if (_totalMinted() + _mintAmount > maxSupply) revert MintedOut();
        _;
    }

    // =========================================================================
    //                           Minting Functions
    // =========================================================================

    function publicMint(uint256 _mintAmount)
    public
    payable
    mintCompliance(_mintAmount, Status.Public)
    {
        _mint(msg.sender, _mintAmount);
    }

    function ownerMintForAddress(address _receiver, uint256 _mintAmount)
    public
    onlyOwner
    ownerMintCompliance(_mintAmount)
    {
        _mint(_receiver, _mintAmount);
    }

    // =========================================================================
    //                           Owner - Mint Details Functions
    // =========================================================================

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxAmountPerTx(uint256 _amount) public onlyOwner {
        maxAmountPerTx = _amount;
    }

    function setLimitPerWallet(uint256 _amount) public onlyOwner {
        limitPerWallet = _amount;
    }

    // =========================================================================
    //                           Owner - Misc Functions
    // =========================================================================

    function setStatus(Status _status) public onlyOwner {
        status = _status;
    }

    function withdraw() public onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed");
    }

    // =========================================================================
    //                           Override Functions
    // =========================================================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        return "";
    }
}
