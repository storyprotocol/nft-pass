// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { Base64 } from 'base64-sol/base64.sol';
import "hardhat/console.sol";
import "./interfaces/IOffChainDataSource.sol";


contract StoryPass is ERC721URIStorage {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string private constant _SVG_START_TAG = '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
    string private constant _SVG_END_TAG = '</svg>';

    Counters.Counter private _tokenIds;
    string[] public grades = ["Bronze", "Silver", "Gold"];
    string[] private backgrounds = ["peru", "silver", "gold"];

    mapping (uint => uint) public tokenGrades;

    mapping (address => string) public registeredBadges;
    address[] public registeredNfts;
    IOffChainDataSource public offChainDS;

    struct TokenURIParams {
        string passId;
        string grade;
        string name;
        string description;
        string background;
        string badges;
        string offChainData;
    }

    struct SVGParams {
        string passId;
        string grade;
        string background;
        string badges;
        string offChainData;
    }


    constructor() ERC721 ("StoryPass", "SPASS") {

    }

    function setOffChainDataSource(IOffChainDataSource offChainDS_) external{
        offChainDS = offChainDS_;
    }

    function getOffChainData(uint tokenId_) internal view returns(string memory data) {
        address owner = ownerOf(tokenId_);
        if (address(offChainDS) != address(0)) {
            data = offChainDS.getData(owner);
        } else {
            data = "";
        }
    }

    function register(address nft, string memory badge) external {
        require(nft != address(0), "invalid address");
        registeredNfts.push(nft);
        registeredBadges[nft] = badge;
    }

    function resetRegisteredNfts() external {
        while (registeredNfts.length > 0) {
            delete registeredBadges[registeredNfts[registeredNfts.length-1]];
            registeredNfts.pop();

        }
    }

    function setGrade(uint tokenId_, uint grade_) external {
        require(_exists(tokenId_), "Grade set of nonexistent token");
        require(grade_ < grades.length, "Grade set of invalid grade");
        tokenGrades[tokenId_] = grade_;
    }

    function mintPass() public {
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenGrades[newItemId] = 0;
        _tokenIds.increment();
    }

    function getBadges(uint tokenId_) internal view returns (string memory) {
        string memory badgeString = "";
        address owner = ownerOf(tokenId_);
        for (uint i = 0; i < registeredNfts.length; i++) {
            if (IERC721(registeredNfts[i]).balanceOf(owner) > 0) {
                badgeString = string(abi.encodePacked(badgeString, registeredBadges[registeredNfts[i]]));
            }
        }
        return badgeString;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'URI query for nonexistent token');
        string memory passId = tokenId_.toString();
        string memory name = string(abi.encodePacked('Story Pass ', passId));
        string memory description = string(abi.encodePacked('Story ', passId, ' is a member of the Story Protocol DAO'));
        string memory grade = grades[tokenGrades[tokenId_]];
        string memory background = backgrounds[tokenGrades[tokenId_]];
        string memory badges = getBadges(tokenId_);
        string memory offChainData = getOffChainData(tokenId_);

        TokenURIParams memory params = TokenURIParams({
        passId: passId,
        grade: grade,
        name: name,
        description: description,
        background: background,
        badges: badges,
        offChainData: offChainData
        });
        return constructTokenURI(params);
    }

    function constructTokenURI(TokenURIParams memory params)
    public
    pure
    returns (string memory)
    {
        string memory image = generateSVGImage(
            SVGParams({ passId: params.passId, grade: params.grade, background: params.background, badges: params.badges, offChainData: params.offChainData })
        );

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    function generateSVGImage(SVGParams memory params)
    internal
    pure
    returns (string memory svg)
    {
        return Base64.encode(bytes(generateSVG(params)));
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {

        string memory svg_start = string(
            abi.encodePacked(
                _SVG_START_TAG,
                '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>'));
        return string(
            abi.encodePacked(
                svg_start,
                '<rect width="100%" height="100%" fill="', params.background, '" />',
                '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle"> ', params.grade, ' Pass ', params.passId, ' </text>',
                '<text x="20%" y="80%" class="base" dominant-baseline="middle" text-anchor="middle"> Achievements : ', params.offChainData, ' </text>',
                params.badges,
                _SVG_END_TAG
            )
        );
    }

}
