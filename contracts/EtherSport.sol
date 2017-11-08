pragma solidity ^0.4.15;

import "./StandardToken.sol";
import "./SafeMath.sol";

contract EtherSport is StandardToken {
    using SafeMath for uint256;

    /*
     *  Metadata
     */
    string public constant name = "Ether Sport";
    string public constant symbol = "ESC";
    uint8 public constant decimals = 18;
    uint256 public constant tokenUnit = 10 ** uint256(decimals);

    /*
     *  Contract owner (Ethersport)
     */
    address public owner;

    /*
     *  Hardware wallets
     */
    address public ethFundAddress;  // Address for ETH owned by Ethersport
    address public escFundAddress;  // Address for ESC allocated to Ethersport

    /*
        *  List of token purchases per address
        *  Same as balances[], except used for individual cap calculations,
        *  because users can transfer tokens out during sale and reset token count in balances.
        */
    mapping (address => uint256) public purchases;
    mapping (uint => address) public allocationsIndex;
    mapping (address => uint256) public allocations;
    uint public allocationsLength;
    mapping (string => mapping (string => uint256)) cd; //crowdsaleData;

    /*
    *  Crowdsale parameters
    */
    bool public isFinalized;
    bool public isStopped;
    uint256 public startBlock;  // Block number when sale period begins
    uint256 public endBlock;  // Block number when sale period ends
    uint256 public assignedSupply;  // Total ESC tokens currently assigned
    uint256 public constant minimumPayment = 5 * (10**14); // 0.0005 ETH
    uint256 public constant escFund = 40 * (10**6) * tokenUnit;  // 40M ESC reserved for development and user growth fund

    /*
    *  Events
    */
    event ClaimESC(address indexed _to, uint256 _value);

    modifier onlyBy(address _account){
        require(msg.sender == _account);
        _;
    }

    function changeOwner(address _newOwner) onlyBy(owner) external {
        owner = _newOwner;
    }

    modifier respectTimeFrame() {
        require(block.number >= startBlock);
        require(block.number < endBlock);
        _;
    }

    modifier salePeriodCompleted() {
        require(block.number >= endBlock || assignedSupply.add(escFund).add(minimumPayment) > totalSupply);
        _;
    }

    modifier isValidState() {
        require(!isFinalized && !isStopped);
        _;
    }

    function allocate(address _escAddress, uint token) internal {
        allocationsIndex[allocationsLength] = _escAddress;
        allocations[_escAddress] = token;
        allocationsLength = allocationsLength + 1;
    }
    /*
     *  Constructor
     */
    function EtherSport(
        address _ethFundAddress,
        uint256 _startBlock,
        uint256 _preIcoHeight,
        uint256 _stage1Height,
        uint256 _stage2Height,
        uint256 _stage3Height,
        uint256 _stage4Height,
        uint256 _endBlockHeight
    )
    public
    {
        require(_ethFundAddress != 0x0);
        require(_startBlock > block.number);

        owner = msg.sender; // Creator of contract is owner
        isFinalized = false; // Controls pre-sale state through crowdsale state
        isStopped   = false; // Circuit breaker (only to be used by contract owner in case of emergency)
        ethFundAddress = _ethFundAddress;
        totalSupply    = 100 * (10**6) * tokenUnit;  // 100M total ESC tokens
        assignedSupply = 0;  // Set starting assigned supply to 0
        //  Stages  |Duration| Start date           | End date             | Amount of       | Price per    | Amount of tokens | Minimum     |
        //          |        |                      |                      | tokens for sale | token in ETH | per 1 ETH        | payment ETH |
        //  --------|--------|----------------------|----------------------|-----------------|--------------|------------------|-------------|
        //  Pre ICO | 1 week | 13.11.2017 12:00 UTC | 19.11.2017 12:00 UTC | 10,000,000      | 0.00050      | 2000.00          | 0.0005      |
        //  1 stage | 1 hour | 21.11.2017 12:00 UTC | 21.11.2017 13:00 UTC | 10,000,000      | 0.00100      | 1000.00          | 0.0005      |
        //  2 stage | 1 day  | 22.11.2017 13:00 UTC | 29.11.2017 13:00 UTC | 15,000,000      | 0.00130      | 769.23           | 0.0005      |
        //  3 stage | 1 week | 22.11.2017 13:00 UTC | 29.11.2017 13:00 UTC | 15,000,000      | 0.00170      | 588.24           | 0.0005      |
        //  4 stage | 3 weeks| 29.11.2017 13:00 UTC | 20.12.2017 13:00 UTC | 20,000,000      | 0.00200      | 500.00           | 0.0005      |
        //  --------|--------|----------------------|----------------------|-----------------|--------------|------------------|-------------|
        //                                                                 | 70,000,000      |
        cd['preIco']['startBlock'] = _startBlock;                 cd['preIco']['endBlock'] = _startBlock + _preIcoHeight;     cd['preIco']['cap'] = 10 * 10**6 * 10**18; cd['preIco']['exRate'] = 200000;
        cd['stage1']['startBlock'] = _startBlock + _stage1Height; cd['stage1']['endBlock'] = _startBlock + _stage2Height - 1; cd['stage1']['cap'] = 10 * 10**6 * 10**18; cd['stage1']['exRate'] = 100000;
        cd['stage2']['startBlock'] = _startBlock + _stage2Height; cd['stage2']['endBlock'] = _startBlock + _stage3Height - 1; cd['stage2']['cap'] = 15 * 10**6 * 10**18; cd['stage2']['exRate'] = 76923;
        cd['stage3']['startBlock'] = _startBlock + _stage3Height; cd['stage3']['endBlock'] = _startBlock + _stage4Height - 1; cd['stage3']['cap'] = 15 * 10**6 * 10**18; cd['stage3']['exRate'] = 58824;
        cd['stage4']['startBlock'] = _startBlock + _stage4Height; cd['stage4']['endBlock'] = _startBlock + _endBlockHeight;   cd['stage4']['cap'] = 20 * 10**6 * 10**18; cd['stage4']['exRate'] = 50000;
        startBlock = _startBlock;
        endBlock   = _startBlock +_endBlockHeight;

        escFundAddress = 0xd5f1a39c084b18faf7441ec5b7b97077c71a6750;
        allocationsLength = 0;
        //• 13% (13’000’000 ESC) will remain at EtherSport for supporting the game process;
        allocate(escFundAddress, 0); // will remain at EtherSport for supporting the game process (remaining unassigned supply);
        allocate(0xe3d95ea237ecea3c80d08c8bd23286df1ed18f11, 5 * 10**6 * 10**18); // will remain at EtherSport for supporting the game process;
        allocate(0xa78061767c8209e4113c9aaaabe6c3a2249c008f, 4 * 10**6 * 10**18); // will remain at EtherSport for supporting the game process;
        allocate(0xab999ec7e0a94ebf388cdfbd84ab7aeb38290c37, 4 * 10**6 * 10**18); // will remain at EtherSport for supporting the game process;
        //• 5% (5’000’000 ESC) will be allocated for the bounty campaign;
        allocate(0x230bcdb2a54de4f1acd2431b2a62a94cbcd6cb76, 3 * 10**6 * 10**18); // will be allocated for the bounty campaign;
        allocate(0x01c62edeaeac6b37dc03e1c8de2d6d2600094ef1, 2 * 10**6 * 10**18); // will be allocated for the bounty campaign;
        //• 5% (5’000’000 ESC) will be paid to the project founders and the team;
        allocate(0x899cffc54306ee1b28921fa0ce3e525500361988, 2 * 10**6 * 10**18); // will be paid to the project founders and the team;
        allocate(0xb27d5195c460489ad540c4cb254d606df8826165, 2 * 10**6 * 10**18); // will be paid to the project founders and the team;
        allocate(0xba6643acc789edee6c3828bba4aa74ab7f8cf758, 1 * 10**6 * 10**18); // will be paid to the project founders and the team;
        //• 5% (5’000’000 ESC) will be paid to the Angel investors;
        allocate(0x9b14405a45e543730e46ac24b1f38305c593df6b, 2 * 10**6 * 10**18); // will be paid to the Angel investors.
        allocate(0x4cc13478b4ee4702aa9701d7866773ab07a4a48c, 2 * 10**6 * 10**18); // will be paid to the Angel investors.
        allocate(0x704c1930bd8b2650b4c334ef4923ffa228e9e725, 1 * 10**6 * 10**18); // will be paid to the Angel investors.
        //• 1% (1’000’000 ESC) will be left in the system for building the first jackpot;
        allocate(0xef06c0bae3808e1233886d9423f74a2e84f17564, 1 * 10**6 * 10**18); // will be left in the system for building the first jackpot;
        //• 1% (1’000’000 ESC) will be distributed among advisors;
        allocate(0xacc25d1c83d7d3564b008cadd80d360104c46e5c, 1 * 10**6 * 10**18); // will be distributed among advisors;

    }

    /// @notice Stop sale in case of emergency (i.e. circuit breaker)
    /// @dev Only allowed to be called by the owner
    function stopSale() onlyBy(owner) external {
        isStopped = true;
    }

    /// @notice Restart sale in case of an emergency stop
    /// @dev Only allowed to be called by the owner
    function restartSale() onlyBy(owner) external {
        isStopped = false;
    }

    /// @dev Fallback function can be used to buy tokens
    function () payable public {
        claimTokens();
    }

    /// @notice Calculate rate based on block number
    function calculateTokenExchangeRate() internal returns (uint256) {
        if (cd['preIco']['startBlock'] <= block.number && block.number <= cd['preIco']['endBlock']) { return cd['preIco']['exRate']; }
        if (cd['stage1']['startBlock'] <= block.number && block.number <= cd['stage1']['endBlock']) { return cd['stage1']['exRate']; }
        if (cd['stage2']['startBlock'] <= block.number && block.number <= cd['stage2']['endBlock']) { return cd['stage2']['exRate']; }
        if (cd['stage3']['startBlock'] <= block.number && block.number <= cd['stage3']['endBlock']) { return cd['stage3']['exRate']; }
        if (cd['stage4']['startBlock'] <= block.number && block.number <= cd['stage4']['endBlock']) { return cd['stage4']['exRate']; }
        // in case between Pre-ICO and ICO
        return 0;
    }

    function maximumTokensToBuy() constant internal returns (uint256) {
        uint256 maximum = 0;
        if (cd['preIco']['startBlock'] <= block.number) { maximum = maximum.add(cd['preIco']['cap']); }
        if (cd['stage1']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage1']['cap']); }
        if (cd['stage2']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage2']['cap']); }
        if (cd['stage3']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage3']['cap']); }
        if (cd['stage4']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage4']['cap']); }
        return maximum.sub(assignedSupply);
    }

    /// @notice Create `msg.value` ETH worth of ESC
    /// @dev Only allowed to be called within the timeframe of the sale period
    function claimTokens() respectTimeFrame isValidState payable public {
        require(msg.value >= minimumPayment);

        uint256 tokenExchangeRate = calculateTokenExchangeRate();
        // tokenExchangeRate == 0 mean that now not valid time to take part in crowdsale event
        require(tokenExchangeRate > 0);

        uint256 tokens = msg.value.mul(tokenExchangeRate).div(100);

        // Check that we can sell this amount of tokens in the moment
        require(tokens <= maximumTokensToBuy());

        // Check that we're not over totals
        uint256 checkedSupply = assignedSupply.add(tokens);

        // Return money if we're over total token supply
        require(checkedSupply.add(escFund) <= totalSupply);

        balances[msg.sender] = balances[msg.sender].add(tokens);
        purchases[msg.sender] = purchases[msg.sender].add(tokens);

        assignedSupply = checkedSupply;
        ClaimESC(msg.sender, tokens);  // Logs token creation for UI purposes
        // As per ERC20 spec, a token contract which creates new tokens SHOULD trigger a Transfer event with the _from address
        // set to 0x0 when tokens are created (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md)
        Transfer(0x0, msg.sender, tokens);
    }

    /// @notice Sends the ETH to ETH fund wallet and finalizes the token sale
    function finalize() salePeriodCompleted isValidState onlyBy(owner) external {
        // Upon successful completion of sale, send tokens to ESC fund
        balances[escFundAddress] = balances[escFundAddress].add(escFund);
        assignedSupply = assignedSupply.add(escFund);
        ClaimESC(escFundAddress, escFund);   // Log tokens claimed by Ethersport ESC fund
        Transfer(0x0, escFundAddress, escFund);


        for(uint i=0;i<allocationsLength;i++)
        {
            balances[allocationsIndex[i]] = balances[allocationsIndex[i]].add(allocations[allocationsIndex[i]]);
            ClaimESC(allocationsIndex[i], allocations[allocationsIndex[i]]);  // Log tokens claimed by Ethersport ESC fund
            Transfer(0x0, allocationsIndex[i], allocations[allocationsIndex[i]]);
        }

        // In the case where not all 70M ESC allocated to crowdfund participants
        // is sold, send the remaining unassigned supply to ESC fund address,
        // which will then be used to fund the user growth pool.
        if (assignedSupply < totalSupply) {
            uint256 unassignedSupply = totalSupply.sub(assignedSupply);
            balances[escFundAddress] = balances[escFundAddress].add(unassignedSupply);
            assignedSupply = assignedSupply.add(unassignedSupply);

            ClaimESC(escFundAddress, unassignedSupply);  // Log tokens claimed by Ethersport ESC fund
            Transfer(0x0, escFundAddress, unassignedSupply);
        }

        ethFundAddress.transfer(this.balance);

        isFinalized = true; // Finalize sale
    }
}