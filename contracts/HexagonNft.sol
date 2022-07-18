// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Openzeppelin contracts
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HexagonNft is ERC721A, Ownable, ReentrancyGuard {
    // general
    uint256 public collectionSize = 100;
    string public tokenURI;

    // normal mint
    uint256 public mintPrice = 0.4 ether;
    uint256 public maxPerWalletMint = 4;
    bool public mintingEnabled;

    // wl / presale mint
    uint256 public presalePrice = 0.1 ether;
    bool public presaleEnabled;

    mapping(address => uint256) presaleList;

    // events
    event Minted(address indexed to, string indexed tokenURI);

    constructor() ERC721A("HexagonNFT", "HXNFT") {}

    modifier verifyUser() {
        require(
            tx.origin == msg.sender,
            "this operation can only be performed by a user and not a contract"
        );
        _;
    }

    // Base URI Functions
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenURI;
    }

    function setTokenURI(string calldata uri) external onlyOwner {
        tokenURI = uri;
    }

    // Enable/Disable Minting Functions
    function enableMinting(bool enabled) public onlyOwner {
        mintingEnabled = enabled;
    }

    function enablePresale(bool enabled) public onlyOwner {
        presaleEnabled = enabled;
    }

    // Mint Functions
    function presaleMint(uint256 quantity) public payable verifyUser {
        require(presaleEnabled, "Presale minting has not begun yet");
        require(presaleList[msg.sender] > 0, "not eligible for presale mint");
        require(
            msg.value >= presalePrice * quantity,
            "not enough ether to mint"
        );
        require(
            quantity <= presaleList[msg.sender],
            "You can only mint up to 2 tokens per wallet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Max supply reached"
        );

        presaleList[msg.sender] = presaleList[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfPriceisOver(presalePrice * quantity);
    }

    function mint(uint256 quantity) public payable verifyUser {
        require(mintingEnabled, "Presale minting has not begun yet");
        require(
            presaleList[msg.sender] > 0,
            "not eligible for presaleList mint"
        );
        require(
            msg.value >= presalePrice * quantity,
            "not enough ether to mint"
        );
        require(
            totalMinted(msg.sender) + quantity <= maxPerWalletMint,
            "You can only mint up to 4 tokens per wallet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Max supply reached"
        );

        _safeMint(msg.sender, quantity);
        refundIfPriceisOver(presalePrice * quantity);
    }

    // Presale Function
    function setPresaleList(address[] memory addresses, uint256 maxMintAmount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleList[addresses[i]] = maxMintAmount;
        }
    }

    // Extra Functions
    function refundIfPriceisOver(uint256 amount) private {
        require(msg.value >= amount, "Need to send more ETH.");
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function totalMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    function getNftData(uint256 id)
        public
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(id);
    }

    // Withdraw Function

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer / Withdrawal failed");
    }
}
