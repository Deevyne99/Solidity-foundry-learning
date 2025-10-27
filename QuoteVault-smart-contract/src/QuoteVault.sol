// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract QuoteVault {
    //create a Quote vault where users will enter into a lottery to win a prize
    //users will enter the lottery by first paying an entry fee
    //users will then enter a quote into the lottery
    //at the end of the lottery a random winner will be selected from the pool of users
    //the winner will receive the entire balance of the contract
    //the owner of the contract will receive a percentage of the balance as a fee for hosting
    //the lottery will run for a set period of time
    //the lottery will be automated using chainlink keepers
    //the random winner will be selected using chainlink VRF

    uint256 public number;

    struct Quote {
        string author;
        string quote;
        uint256 time;
        address userAddress;
    }

    mapping(address => Quote[]) public userQuotes;
    address[] private usersAddress;
    address private immutable i_owner;
    uint256 public s_quoteCount;

    constructor() {
        i_owner = msg.sender;
    }

    function addQuote(string memory _author, string memory _quote) public {
        //validate Author cannot be empty
        require(bytes(_author).length > 0, "Author cannot be empty ");
        //validate Quote cannot be empty
        require(bytes(_quote).length > 0, "Quotes cannot be empty");
        //validate time posted

        //validate Quote cannot be empty
        require(msg.sender != address(0), "Please enter a valid address");

        //check if the user has added a quoute befor now
        // if (bytes(userQuotes[msg.sender].author).length == 0) {
        //     usersAddress.push(msg.sender);
        // }
    }
}
