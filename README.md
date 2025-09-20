# RecognitionVote

RecognitionVote is a transparent platform for industry honors and professional achievement awards built on the Stacks blockchain. This smart contract enables organizations to create awards, nominate candidates, and conduct transparent voting for industry recognition and professional achievements.

## Features

- **Decentralized Award Management**: Create and manage industry awards and professional recognition programs
- **Multi-Phase Process**: Structured nomination and voting phases with time-based controls
- **Transparent Voting**: All votes are recorded on-chain ensuring complete transparency
- **Access Control**: Role-based permissions for award organizers and contract administration
- **Anti-Double Voting**: Built-in mechanisms to prevent duplicate votes
- **Award Categories**: Support for different award categories and types
- **Automated Winner Determination**: Smart contract logic to determine award winners
- **Time-Based Controls**: Configurable nomination and voting periods

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Contract Version**: 1.0

## Project Structure

```
RecognitionVote/
├── README.md
└── RecognitionVote_contract/
    ├── contracts/
    │   └── RecognitionVote.clar          # Main smart contract
    ├── tests/
    │   └── RecognitionVote.test.ts       # Contract tests
    ├── settings/
    │   ├── Devnet.toml                   # Development network config
    │   ├── Testnet.toml                  # Testnet config
    │   └── Mainnet.toml                  # Mainnet config
    ├── Clarinet.toml                     # Project configuration
    ├── package.json                      # Node.js dependencies
    ├── tsconfig.json                     # TypeScript configuration
    └── vitest.config.js                  # Test configuration
```

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd RecognitionVote
```

2. Navigate to the contract directory:
```bash
cd RecognitionVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Creating an Award

```clarity
;; Create a new award with nomination and voting periods
(contract-call? .RecognitionVote create-award
  "Developer of the Year 2024"
  "Annual recognition for outstanding software development contributions"
  "Technology"
  u1704067200  ;; Nomination start (timestamp)
  u1704672000  ;; Nomination end
  u1704758400  ;; Voting start
  u1705363200) ;; Voting end
```

### Nominating a Candidate

```clarity
;; Nominate someone for an award
(contract-call? .RecognitionVote nominate
  u1  ;; award-id
  "Jane Developer"
  "Outstanding contributions to open source projects and mentoring junior developers")
```

### Voting for a Nomination

```clarity
;; Vote for a nomination
(contract-call? .RecognitionVote vote u1) ;; nomination-id
```

### Starting and Closing Voting

```clarity
;; Start voting phase (award creator only)
(contract-call? .RecognitionVote start-voting u1) ;; award-id

;; Close voting and determine winner (award creator only)
(contract-call? .RecognitionVote close-voting u1) ;; award-id
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions

- **`add-organizer(organizer: principal)`** - Add a new award organizer (contract owner only)
- **`remove-organizer(organizer: principal)`** - Remove an award organizer (contract owner only)

#### Award Management

- **`create-award(...)`** - Create a new award with specified parameters
  - `title`: Award title (max 100 characters)
  - `description`: Award description (max 500 characters)
  - `category`: Award category (max 50 characters)
  - `nomination-start/end`: Nomination period timestamps
  - `voting-start/end`: Voting period timestamps

- **`start-voting(award-id: uint)`** - Transition award to voting phase (creator only)
- **`close-voting(award-id: uint)`** - Close voting and determine winner (creator only)

#### Nomination and Voting

- **`nominate(award-id, nominee-name, nominee-description)`** - Submit a nomination
- **`vote(nomination-id: uint)`** - Cast a vote for a nomination

### Read-Only Functions

- **`get-award(award-id: uint)`** - Retrieve award details
- **`get-nomination(nomination-id: uint)`** - Retrieve nomination details
- **`has-voted(voter: principal, nomination-id: uint)`** - Check if user has voted
- **`is-organizer(user: principal)`** - Check if user is an organizer
- **`get-award-status(award-id: uint)`** - Get current award status
- **`is-voting-active(award-id: uint)`** - Check if voting is currently active
- **`is-nomination-active(award-id: uint)`** - Check if nominations are open
- **`get-next-ids()`** - Get next available award and nomination IDs
- **`get-contract-owner()`** - Get contract owner address

### Award Status Codes

- **Status 1**: Open (nominations active)
- **Status 2**: Voting (voting phase active)
- **Status 3**: Closed (voting completed)

### Error Codes

- **u100**: Owner only operation
- **u101**: Resource not found
- **u102**: Unauthorized access
- **u103**: Resource already exists
- **u104**: Invalid status for operation
- **u105**: Voting period closed
- **u106**: User has already voted
- **u107**: Invalid time period configuration

## Deployment Guide

### Development Network (Devnet)

1. Start local devnet:
```bash
clarinet devnet start
```

2. Deploy contract:
```bash
clarinet devnet deploy
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy to testnet:
```bash
clarinet deployment generate --testnet
clarinet deployment apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy to mainnet:
```bash
clarinet deployment generate --mainnet
clarinet deployment apply --mainnet
```

## Testing

Run the test suite:

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

## Security Notes

### Access Control
- Contract owner has administrative privileges
- Award creators can manage their own awards
- Organizers can be added/removed by contract owner only

### Voting Integrity
- Double voting prevention through on-chain tracking
- Time-based controls prevent voting outside designated periods
- Transparent vote counting with immutable records

### Data Validation
- Input length limits prevent spam and storage abuse
- Timestamp validation ensures logical award timelines
- Status checks prevent invalid state transitions

### Best Practices
- Always verify award and nomination IDs before operations
- Check voting periods before attempting to vote
- Validate user permissions before administrative actions
- Monitor gas costs for large-scale operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For issues and questions:
- Create an issue in the repository
- Review the test files for usage examples
- Check the Clarity documentation for language reference