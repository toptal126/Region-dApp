// SPDX-License-Identifier: ISC

pragma solidity ^0.8.11;
struct Rectangle {
    uint256 left;
    uint256 top;
    uint256 right;
    uint256 bottom;
}

struct Property {
    uint256 rectangleCount;
    mapping(uint256 => Rectangle) rectangles;
    // Rectangle[] rectangles;
}
struct TerrainRequest {
    address requestor;
    Rectangle terrain;
    bool approved;
}

// This is a type for a single proposal.
struct Proposal {
    Rectangle newRect;
    uint256 voteCount; // number of accumulated votes
    bool active; // is valid proposal
}

// Library for using Rectangle
library LibRectangle {
    // Check if the rectangle is valid
    function checkValid(Rectangle memory self) public pure returns (bool) {
        if (self.left > self.right || self.top > self.bottom) return false;
        if (self.left < 0 || self.top < 0 || self.right < 0 || self.bottom < 0)
            return false;
        return true;
    }

    // Check if a point (x, y) is inside a rectangle self except border
    function checkInclusionNotBorder(
        Rectangle storage self,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        if (x < self.left || x > self.right) return false;
        if (y < self.top || y > self.bottom) return false;
        return true;
    }

    // Check if a point (x, y) is inside a rectangle self including border
    function checkInclusion(
        Rectangle storage self,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        if (x <= self.left || x >= self.right) return false;
        if (y <= self.top || y >= self.bottom) return false;
        return true;
    }

    // Check if a rectangle tar is inside a rectangle self
    function checkInclusion(Rectangle storage self, Rectangle memory tar)
        public
        view
        returns (bool)
    {
        if (
            checkInclusion(self, tar.left, tar.top) &&
            checkInclusion(self, tar.right, tar.bottom)
        ) return true;
        return false;
    }

    // Check if a rectangle tar is collising with rectangle self
    function checkCollision(Rectangle storage self, Rectangle memory tar)
        public
        view
        returns (bool)
    {
        if (
            checkInclusionNotBorder(self, tar.left, tar.top) ||
            checkInclusionNotBorder(self, tar.left, tar.bottom) ||
            checkInclusionNotBorder(self, tar.right, tar.top) ||
            checkInclusionNotBorder(self, tar.right, tar.bottom)
        ) return true;
        return false;
    }
}
