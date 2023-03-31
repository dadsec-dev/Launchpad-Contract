// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title Oracle-Nova LaunchPad
 * @author Stanley Dera
 * @notice A launcpad contract where projects can host ICOs after being fully vetted by Oraclex team 
 * @notice There is a platform fee of 10% for every raise
 */
contract OraclePAD is Ownable {
    
    IERC20 public nativeToken;
    address public admin;
    

    uint256 constant SECONDS_PER_YEAR = 31536000;

    struct launchpad {
        IERC20 token;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 totalAmountToBeDistributed;
        uint256 exchangeRatio;
        uint256 startTime;
        uint256 endTime;
        uint256 totalRaised;
        bool isActive;
        address projectOwner;
        uint256 softcap;
        uint256 hardcap;
        // string  unsoldTokens;

    }

    mapping (address => launchpad) launchpads;
    mapping (address => uint256) userContribution;
    mapping(address => bool) hasParticipated;

    constructor(address _nativeToken, address _admin) {
        nativeToken = IERC20(_nativeToken);
        admin = _admin;
    }
    

    error CANNOT_BE_ADDRESS_ZERO();
    error MIN_DEPOSIT_MUST_GREATER_THAN_ZERO();
    error MAX_DEPOSIT_MUST_BE_GREATER_MIN_DEPOSIT();
    error MAX_DEPOSIT_MUST_BE_GREATER_ZERO();
    error TOTAL_AMOUNT_TO_BE_DISTRIBUTED_MUST_BE_GREATER_THAN_ZERO();
    error EXCHANGERATIO_MUST_BE_GREATER_THAN_ZERO();
    error START_TIME_SHOULD_NOT_BE_LESS_THAN_BLOCK_DOT_TIMESTAMP();
    error END_TIME_MUST_BE_GREATER_THAN_START_TIME();
    error YOU_CANNOT_CONTRIBUTE_ZERO();
    error LAUNCHPAD_NOT_ACTIVE();
    error CANNOT_CONTRIBUTE_BELOW_MINDEPOSIT();
    error AMOUNT_IS_MORE_THAN_MAXDEPOSIT();
    error INVALID_TOKEN();
    error TOKEN_LAUNCHPAD_IS_INACTIVE();
    error INSUFFICIENT_BALANCE();
    error CANNOT_PARTICIPATE_TWICE();
    error LAUNCH_STILL_ACTIVE();
    error DID_NOT_PARTICIPATE();
    error LAUNCH_ACTIVE();
    error NOTHING_WAS_RAISED();

    /**
     * 
     * @param _token contractaddress of the token 
     * @param _minDeposit minimum deposit for every participant
     * @param _maxDeposit maximum deposit for every participant
     * @param _totalAmountToBeDistributed totalAmount to be distributed
     * @param _exchangeRatio exchange rate for native coin to presale token
     * @param _startTime when the launchpad commences
     * @param _endTime when launchpad ends
     * @param _softcap minimum target raise
     * @param _hardcap maximum target raise
     * @param _projectOwner project's team /owners wallet address
     */
    function initiateTokenLaunch(address _token, uint256 _minDeposit, uint256 _maxDeposit, uint _totalAmountToBeDistributed, uint256 _exchangeRatio, uint256 _startTime, uint256 _endTime, uint256 _softcap, uint256 _hardcap, address _projectOwner) external onlyOwner  {
        // require(_token != address(0), "Token address cannot be address zero");
        if (_token == address(0)) {revert CANNOT_BE_ADDRESS_ZERO();}
        if (_minDeposit <= 0) {revert MIN_DEPOSIT_MUST_GREATER_THAN_ZERO();}
        if(_maxDeposit <= _minDeposit) {revert MAX_DEPOSIT_MUST_BE_GREATER_MIN_DEPOSIT();}
        if(_maxDeposit <= 0 ) {revert MAX_DEPOSIT_MUST_BE_GREATER_ZERO();}
        if(_totalAmountToBeDistributed <= 0) {revert TOTAL_AMOUNT_TO_BE_DISTRIBUTED_MUST_BE_GREATER_THAN_ZERO();}
        if(_exchangeRatio <= 0) {revert EXCHANGERATIO_MUST_BE_GREATER_THAN_ZERO();}
        if(_startTime < block.timestamp) {revert START_TIME_SHOULD_NOT_BE_LESS_THAN_BLOCK_DOT_TIMESTAMP();}
        if(_endTime <= _startTime) {revert END_TIME_MUST_BE_GREATER_THAN_START_TIME();}


        launchpad storage tokenLaunch = launchpads[_token];

        require(tokenLaunch.isActive = false, "token has already launched");

        tokenLaunch.token = IERC20(_token);
        tokenLaunch.minDeposit = _minDeposit;
        tokenLaunch.maxDeposit = _maxDeposit;
        tokenLaunch.totalAmountToBeDistributed = _totalAmountToBeDistributed;
        tokenLaunch.exchangeRatio = _exchangeRatio;
        tokenLaunch.startTime = _startTime;
        tokenLaunch.endTime = _endTime;
        tokenLaunch.isActive = true;
        tokenLaunch.projectOwner = _projectOwner;
        tokenLaunch.softcap = _softcap;
        tokenLaunch.hardcap = _hardcap;
        
    }
    
    /**
     * 
     * @param _tokenToContribute contract address of the token a user wishes to contribute to
     * @param _amount amount user wants to contribute
     */

    function contribute(IERC20 _tokenToContribute, uint256 _amount) public {

        if(_amount == 0) {revert YOU_CANNOT_CONTRIBUTE_ZERO();}


        launchpad storage launch = launchpads[address(_tokenToContribute)];

        if(launch.isActive == false) {revert LAUNCHPAD_NOT_ACTIVE();}
        if(_amount < launch.minDeposit) {revert CANNOT_CONTRIBUTE_BELOW_MINDEPOSIT();}
        if(_amount > launch.maxDeposit) {revert AMOUNT_IS_MORE_THAN_MAXDEPOSIT();}
        if(_tokenToContribute != launch.token) {revert INVALID_TOKEN();}
        if (block.timestamp < launch.startTime && block.timestamp >= launch.endTime) {revert TOKEN_LAUNCHPAD_IS_INACTIVE();}
        if(nativeToken.balanceOf(msg.sender) < _amount) {revert INSUFFICIENT_BALANCE();}

        // require(launch.isActive = true, "Launcpad isn't active");
        // require(_amount > launch.minDeposit, "Deposit amount is less than minimum Deposit for this token IFO");
        // require(_amount <= launch.maxDeposit, "Amount is more than the maximum deposit amount");
        // require(_tokenToContribute == launch.token, "Invalid token input");
        // require(_amount < launch.totalAmountToBeDistributed, "you cannot buy everything");
        // require(block.timestamp > launch.startTime && block.timestamp <= launch.endTime, "Token launchpad is inactive");
        // require(nativeToken.balanceOf(msg.sender) >= _amount, "Insufficient Balance");

        nativeToken.transferFrom(msg.sender, address(this), _amount);
        launch.totalRaised += _amount;

        if(userContribution[msg.sender] > 0) {revert CANNOT_PARTICIPATE_TWICE();}
        // require(userContribution[msg.sender] == 0, "You cannot participate more than once");
       
        userContribution[msg.sender] = _amount;


        hasParticipated[msg.sender] = true;



    }

    /**
     * 
     * @param _tokenAddress contract address of token to be withdrawn 
     */

    function withdraw(IERC20 _tokenAddress) public{
        
        launchpad storage launch = launchpads[address(_tokenAddress)];
        uint256 userAmountMultiplier = launch.exchangeRatio;
        IERC20 token = launch.token;

        if(block.timestamp < launch.endTime) {revert LAUNCH_STILL_ACTIVE();}

        // require(block.timestamp > launch.endTime, "LaunchPad hasn't ended");
        if(launch.isActive == true) {revert LAUNCH_STILL_ACTIVE();}
        // require(launch.isActive = false, "LauncPad has ended");
        if(hasParticipated[msg.sender] == false) {revert DID_NOT_PARTICIPATE();}
        // require(hasParticipated[msg.sender] = true, "You didn't participate in this launchpad");

        uint256 userAmountToRecive = userContribution[msg.sender] * userAmountMultiplier;

        token.transfer(msg.sender, userAmountToRecive);

    }

    function withdrawRaisedFunds(IERC20 _token) external onlyOwner {
        launchpad storage tokenLaunch = launchpads[address(_token)];

        if(tokenLaunch.endTime > block.timestamp) {revert LAUNCH_ACTIVE();}
        // require(tokenLaunch.endTime < block.timestamp, "launchpad hasn't ended yet");

        uint256 totalRaised = tokenLaunch.totalRaised;
        uint256 platformFee = (totalRaised * 10) / 100; //platfrom percentage from raise
        uint256 amountToWithdrawAfterPlatformFee = totalRaised - platformFee;

        if(totalRaised < 1) {revert NOTHING_WAS_RAISED();}
        // require(totalRaised > 0, "Unfortunatley, you didn't raise anything lmao");

        IERC20(_token).transfer(admin, platformFee);//withdraw platform fee for this particular token auction to the platform owner/team address
        IERC20(_token).transfer(tokenLaunch.projectOwner, amountToWithdrawAfterPlatformFee);//withdraw the rest to project owner address

        tokenLaunch.totalRaised = 0;//reset totalRaised;

        

    }





}
