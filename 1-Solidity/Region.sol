// SPDX-License-Identifier: ISC

pragma solidity ^0.8.11;
import "./LibRectangle.sol";

contract Region {
    // Contract creator
    address public creator = msg.sender;

    // Maps Count
    uint256 public mapsCount = 0;
    // maps data
    mapping(uint256 => Rectangle) public maps;
    // Plots data
    uint256 ownersCount = 0;
    mapping(uint256 => address) private owners; // Plot owners or voters
    mapping(address => Property) public plots;
    mapping(address => bool) public votings;
    // Rectangle request proposal array
    uint256 requestQueueLength = 0;
    mapping(uint256 => TerrainRequest) public requestQueue;

    // Proposal for extending map
    Proposal public extendingMap;

    error Unauthorized();
    modifier onlyBy(address _account) {
        if (msg.sender != _account) revert Unauthorized();
        _;
    }

    // Initialize map with Rectangle (0, 0, 30, 30)
    constructor() {
        //Add creator to owner list
        ownersCount = 1;
        owners[ownersCount] = msg.sender;
        // Make initial proposal
        extendingMap = Proposal(Rectangle(0, 0, 30, 30), 1, true);
        addMap();
    }

    function getRequestQueueLength()
        public
        view
        onlyBy(creator)
        returns (uint256)
    {
        return requestQueueLength;
    }

    // Extend a new map
    function addMap() public {
        Rectangle memory _newMap = extendingMap.newRect;
        // Check if the _newMap is valid for extending
        require(LibRectangle.checkValid(_newMap));
        // Require is valid voting
        require(
            extendingMap.voteCount == ownersCount,
            "Insufficient voting result"
        );
        for (uint256 index = 1; index <= mapsCount; index++) {
            require(
                !LibRectangle.checkCollision(maps[index], _newMap),
                "Unavailable rectangle"
            );
        }
        // Extend map
        mapsCount++;
        maps[mapsCount] = _newMap;

        // Clear proposal
        for (uint256 index = 1; index < ownersCount; index++) {
            votings[owners[index]] = false;
        }
        extendingMap.active = false;
        extendingMap.voteCount = 0;
    }

    // Propose extending map
    function proposeExtendingMap(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public onlyBy(creator) {
        Rectangle memory _newMap = Rectangle(x1, y1, x2, y2);
        require(LibRectangle.checkValid(_newMap));
        require(extendingMap.active == false, "Prior voting not finished yet");

        for (uint256 index = 1; index <= mapsCount; index++) {
            require(
                !LibRectangle.checkCollision(maps[index], _newMap),
                "Unavailable rectangle"
            );
        }
        extendingMap = Proposal(_newMap, 0, true);
    }

    // Vote to extending map
    function voteExtendingMap() public {
        require(plots[msg.sender].rectangleCount > 0, "Not an owner"); // Must be owner
        require(votings[msg.sender] == false, "Already voted");
        require(extendingMap.active == true, "Invalid voting");
        votings[msg.sender] = true;
        extendingMap.voteCount++;
        // if all owners voted
        if (extendingMap.voteCount == ownersCount) addMap();
    }

    // Request getting terrain from map
    function requestTerrain(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public {
        Rectangle memory _rect = Rectangle(x1, y1, x2, y2);
        require(LibRectangle.checkValid(_rect));
        //Check if the request rectangle is included in maps
        uint256 mapID = 0;
        for (uint256 index = 1; index <= mapsCount; index++) {
            if (LibRectangle.checkInclusion(maps[index], _rect) == true) {
                mapID = index;
                break;
            }
        }
        require(mapID != 0, "This rectangle is outside of out maps");

        // check if the requesting rectangle is not collising with other rectangles
        for (uint256 index = 1; index < ownersCount; index++) {
            for (
                uint256 rectId = 0;
                rectId < plots[owners[index]].rectangleCount;
                rectId++
            ) {
                require(
                    LibRectangle.checkCollision(
                        plots[owners[index]].rectangles[rectId],
                        _rect
                    ) == false,
                    "This rectangle is unavailable"
                );
            }
        }

        requestQueueLength++;
        requestQueue[requestQueueLength] = TerrainRequest(
            msg.sender,
            _rect,
            false
        );
    }

    // Approve terrain request
    function approveRequest(uint256 _requestId) public onlyBy(creator) {
        require(
            _requestId <= requestQueueLength && _requestId > 0,
            "Invalid requestId"
        );
        require(requestQueue[_requestId].approved == false, "Already approved");

        // check if the requesting rectangle is not collising with other rectangles
        // double checks due to prior approvements of others
        for (uint256 index = 1; index < ownersCount; index++) {
            for (
                uint256 rectId = 0;
                rectId < plots[owners[index]].rectangleCount;
                rectId++
            ) {
                require(
                    LibRectangle.checkCollision(
                        plots[owners[index]].rectangles[rectId],
                        requestQueue[_requestId].terrain
                    ) == false,
                    "This rectangle is unavailable"
                );
            }
        }

        requestQueue[_requestId].approved = true;

        address _requestor = requestQueue[_requestId].requestor;
        //check if send is new owner
        if (plots[_requestor].rectangleCount == 0) {
            ownersCount++;
            owners[ownersCount] = _requestor;
        }
        plots[_requestor].rectangleCount++;
        plots[_requestor].rectangles[
            plots[_requestor].rectangleCount
        ] = requestQueue[_requestId].terrain;
    }
}
