//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

error SaleNotStarted();
error SaleInProgress();
error InsufficientPayment();
error IncorrectPayment();
error AccountNotAllowlisted();
error AmountExceedsSupply();
error AmountExceedsAllowlistLimit();
error AmountExceedsTransactionLimit();

contract MyNFT is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRESALE_SUPPLY = 4230;
    uint256 public constant PUBLIC_SALE_MINT_LIMIT = 1;
    uint256 private constant MAX_MINTS_PER_TX = 5;

    string private _baseTokenUri;

    // Presale
    uint256 public presalePrice = 0.02 ether;
    bool public isPresaleActive = false;
    bytes32 private merkleRoot;
    mapping(address => bool) private _allowlistClaimed;

    // Public sale
    uint256 public publicSalePrice = 0.02 ether;
    bool public isPublicSaleActive = false;

    constructor() ERC721A("MyNFT", "MYNFT") {}

    function publicSaleMint(uint256 quantity) external payable nonReentrant {
        if (!isPublicSaleActive) revert SaleNotStarted();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();
        if (publicSalePrice * quantity != msg.value) revert IncorrectPayment();
        if (quantity > MAX_MINTS_PER_TX) revert AmountExceedsTransactionLimit();

        _safeMint(msg.sender, quantity);
    }

    function presaleMint(bytes32[] memory merkleProof, uint256 quantity)
        external
        payable
        nonReentrant
    {
        if (!isPresaleActive) revert SaleNotStarted();
        if (totalSupply() + quantity > PRESALE_SUPPLY)
            revert AmountExceedsSupply();
        if (!_isAllowlisted(merkleProof)) revert AccountNotAllowlisted();
        if (allowlistClaimed(msg.sender)) revert AmountExceedsAllowlistLimit();
        if (presalePrice * quantity != msg.value) revert IncorrectPayment();
        if (quantity > MAX_MINTS_PER_TX) revert AmountExceedsTransactionLimit();

        _allowlistClaimed[msg.sender] = true;

        _safeMint(msg.sender, quantity);
    }

    function _isAllowlisted(bytes32[] memory merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function allowlistClaimed(address account) public view returns (bool) {
        return _allowlistClaimed[account];
    }

    function setPresalePrice(uint256 price) external onlyOwner {
        presalePrice = price;
    }

    function setPublicSaleStartPrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    function setPublicSaleActive(bool isActive) external onlyOwner {
        isPublicSaleActive = isActive;
    }

    function setPresaleActive(bool isActive) external onlyOwner {
        isPresaleActive = isActive;
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenUri = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
