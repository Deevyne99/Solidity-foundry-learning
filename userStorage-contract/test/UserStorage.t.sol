// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {UserStorage} from "../src/UserStorage.sol";

contract UserStorageTest is Test {
    UserStorage public userStorage;

    function setUp() public {
        // Deploy the UserStorage contract before each test
        // This ensures that each test starts with a fresh instance of UserStorage
        UserStorage deployer = new UserStorage();
        userStorage = deployer;
    }

    function testStoreUserData() public {
        // Test that user data can be stored successfully
        // This should store the user data for the address that calls this function
        userStorage.store("Alice", 30);
        UserStorage.userData memory data = userStorage.retrieveDetails(
            address(this)
        );
        assertEq(data.name, "Alice");
        assertEq(data.age, 30);
    }

    function testStoreUserRevertIfEmptyNameOrAge() public {
        //test that storing user data reverts if name or age is invalid
        // This should revert since the name is empty and age is zero
        vm.expectRevert("Name and age must be valid");
        userStorage.store("", 0);
    }

    function testGetOwner() public view {
        // Check if the owner is set correctly
        // The owner should be the address that deployed the contract
        address owner = userStorage.getOwner();
        assertEq(owner, address(this));
    }

    function testUpdateRevertsIfUserDoesNotExist() public {
        // Attempt to update user details without storing first
        // This should revert since the user does not exist
        vm.expectRevert("User does not exist");
        userStorage.updateDetails("Alice", 30);
    }

    function testUpdateUser() public {
        //First store the user data
        userStorage.store("Alice", 30);

        //Then update the user data
        userStorage.updateDetails("Alice", 40);
        UserStorage.userData memory data = userStorage.retrieveDetails(
            address(this)
        );
        assertEq(data.name, "Alice");
        assertEq(data.age, 40);
    }

    function testDeleteDetailsSuccessfully() public {
        // First, store a profile
        userStorage.store("Alice", 25);

        // Then, delete it
        userStorage.deleteDetails();

        // Verify deletion
        UserStorage.userData memory data = userStorage.retrieveDetails(
            address(this)
        );
        assertEq(data.name, ""); // name should be empty
        assertEq(data.age, 0); // age should be 0
    }
}
