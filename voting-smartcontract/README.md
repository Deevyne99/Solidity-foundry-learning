## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# 🗳️ INEC-Style Voting Smart Contract (Solidity)

## 📌 Project Overview

This project implements a **time-bound, one-person-one-vote voting smart contract** in Solidity, modeled after traditional INEC-style election rules.

The system ensures:

- No vote delegation
- No double voting
- Only registered voters can vote
- Voting automatically closes after a fixed deadline (24 hours)
- Results are transparent, deterministic, and verifiable on-chain

The contract is intentionally simple, auditable, and does **not** rely on off-chain automation or oracles.

---

## 🎯 Objectives

- Enforce **one-person-one-vote**
- Prevent vote delegation and proxy voting
- Prevent voting after the deadline
- Provide clear and verifiable election results
- Keep the system minimal and secure

---

## 🚫 Out of Scope

- Identity verification (handled off-chain)
- Vote secrecy beyond wallet abstraction
- Delegated or weighted voting
- Off-chain automation (e.g., Chainlink Automation)
- Governance upgrades

---

## 👥 Roles

### Election Administrator

- Deploys the contract
- Registers eligible voters
- Cannot vote more than once
- Cannot alter votes or results

### Voter

- Must be registered
- Can vote exactly once
- Cannot vote after the election deadline

---

## 🧱 Core Design Principles

1. **One Address = One Vote**
2. **No Delegation**
3. **Strict Voting Deadline**
4. **Immutable Votes**
5. **Transparent Results**
6. **On-Chain Enforcement**

---

## 🗂️ Data Structures (Conceptual)

### Voter

- `isRegistered`: Boolean
- `hasVoted`: Boolean

### Proposal / Candidate

- `name`: Identifier (string or bytes32)
- `voteCount`: Number of votes received

### Election Metadata

- `admin`: Election administrator address
- `votingStartTime`: Timestamp at deployment
- `votingEndTime`: `votingStartTime + 24 hours`

---

## 🔧 Functional Requirements (Step-by-Step)

### 1️⃣ Contract Initialization

- Set administrator address
- Accept list of proposals
- Set voting start time
- Compute voting end time (24 hours)

---

### 2️⃣ Voter Registration

- Only administrator can register voters
- Prevent duplicate registration
- Prevent registering voters who already voted

---

### 3️⃣ Voting Status Tracking

- Determine whether voting is:
  - Not started
  - Ongoing
  - Ended
- Use `block.timestamp` for enforcement

---

### 4️⃣ Vote Casting

- Only registered voters can vote
- Each voter can vote once
- Reject votes after deadline
- Validate proposal index

**State Changes**

- Mark voter as voted
- Increment selected proposal vote count

---

### 5️⃣ Vote Verification

- Public function to check if an address has voted
- Does not reveal vote choice

---

### 6️⃣ Proposal Queries

- Retrieve a single proposal’s details
- Retrieve all proposals

---

### 7️⃣ Result Computation

- Compute winning proposal
- Only callable after voting ends
- Highest vote count wins

---

### 8️⃣ Result Disclosure

- Return the winning proposal name
- Results are immutable after voting ends

---

## ⏱️ Time Enforcement Rules

- Voting automatically stops after `votingEndTime`
- Any vote attempt after the deadline must revert
- Result functions must require voting to have ended

---

## 🔐 Security & Integrity Requirements

- ❌ No delegation logic
- ❌ No vote weighting
- ❌ No re-voting
- ❌ No admin vote override
- ✅ Defensive `require` checks
- ✅ Deterministic results

---

## 📣 Events (Optional but Recommended)

- `VoterRegistered(address voter)`
- `VoteCast(address voter, uint proposalId)`
- `ElectionEnded(uint timestamp)`

---

## ⏳ Development Timeline (4 Hours)

### Hour 1

- Project setup
- Contract skeleton
- Data structures
- Constructor logic

### Hour 2

- Voter registration logic
- Vote casting logic
- Deadline enforcement

### Hour 3

- Query functions
- Result computation
- Event emissions

### Hour 4

- Edge-case testing
- Code cleanup
- Final documentation

---

## ✅ Acceptance Criteria

The project is complete when:

- A voter cannot vote twice
- A voter cannot vote after the deadline
- Vote delegation is impossible
- Results are accurate and verifiable
- Contract compiles and deploys successfully

---

## 🚀 Future Improvements (Optional)

- Commit–reveal voting scheme
- Multi-phase elections
- Gas optimizations
- Layer-2 deployment
- Frontend integration

---

## 📄 License

MIT or GPL-3.0 (choose one)

---

## 🧠 Summary

This project delivers a **simple, secure, INEC-style voting smart contract** that prioritizes fairness, transparency, and correctness over complexity.

Perfect for learning, demos, governance experiments, or small-scale elections.

---
