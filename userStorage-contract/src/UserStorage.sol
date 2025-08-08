// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

// @title UserStorage
// @notice This contract is a placeholder for user storage functionality.

contract UserStorage {
    //allows user to store name and age

    //allows user to update name and age

    //allows user to delete name and age

    //allows user to retrieve name and age

    //owned by the deployer of the contract

    //variable to store user data.abi
    struct userData {
        string name;
        uint256 age;
    }

    mapping(address => userData) userProfile;

    address private i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function store(string memory _name, uint256 _age) public {
        require(
            bytes(_name).length > 0 && _age > 0,
            "Name and age must be valid"
        );

        userProfile[msg.sender] = userData({name: _name, age: _age});
    }

    function retrieveDetails(
        address _user
    ) public view returns (userData memory) {
        userData memory data = userProfile[_user];
        return data;
    }

    function updateDetails(string memory _name, uint256 _age) public {
        require(
            bytes(userProfile[msg.sender].name).length > 0,
            "User does not exist"
        );
        require(
            bytes(_name).length > 0 && _age > 0,
            "Name and age must be valid"
        );

        userData memory data = userData({name: _name, age: _age});
        userProfile[msg.sender] = data;
    }

    function deleteDetails() public {
        require(
            bytes(userProfile[msg.sender].name).length != 0,
            "User does not exist"
        );
        delete userProfile[msg.sender];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
