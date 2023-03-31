// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract StakERC20 is Ownable {
    
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

    }

    mapping (address => launchpad) launchpads;
    mapping (address => uint256) userContribution;
    mapping(address => bool) hasParticipated;

    constructor(address _nativeToken, address _admin) {
        nativeToken = IERC20(_nativeToken);
        admin = _admin;
    }

    function initiateTokenLaunch(address _token, uint256 _minDeposit, uint256 _maxDeposit, uint _totalAmountToBeDistributed, uint256 _exchangeRatio, uint256 _startTime, uint256 _endTime, uint256 _softcap, uint256 _hardcap, address _projectOwner) external onlyOwner  {
        require(_token != address(0), "Token address cannot be address zero");
        require(_minDeposit > 0, "Minimum Deposit must be greater than zero");
        require(_maxDeposit > 0, "MaxDeposit must be greater than zero");
        require(_maxDeposit > _minDeposit, "MaxDeposit must be greater than minDeposit");
        require(_totalAmountToBeDistributed > 0, "Total amount to be distributed must be greater than zero");
        require(_exchangeRatio > 0, "exchange ratio must be greater than zero");
        require(_startTime >= block.timestamp, "Start time must be greater than or less than block timestamp");
        require(_endTime > _startTime, "emdtime must be greater than start time");

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
             

    function contribute(IERC20 _tokenToContribute, uint256 _amount) public {
        //require(_tokenToContribute != address(0), "cannot contribute address zero");
        require(_amount != 0, "You seriously want to contribute 0? c'mon man");
        // require(msg.sender != onlyOwner.address, "admin cannot participate");

        launchpad storage launch = launchpads[address(_tokenToContribute)];

        require(launch.isActive = true, "Launcpad isn't active");
        require(_amount > launch.minDeposit, "Deposit amount is less than minimum Deposit for this token IFO");
        require(_amount <= launch.maxDeposit, "Amount is more than the maximum deposit amount");
        require(_tokenToContribute == launch.token, "Invalid token input");
        require(_amount < launch.totalAmountToBeDistributed, "you cannot buy everything");
        require(block.timestamp > launch.startTime && block.timestamp <= launch.endTime, "Token launchpad is inactive");
        require(nativeToken.balanceOf(msg.sender) >= _amount, "Insufficient Balance");

        nativeToken.transferFrom(msg.sender, address(this), _amount);
        launch.totalRaised += _amount;
        require(userContribution[msg.sender] == 0, "You cannot participate more than once");
       
        userContribution[msg.sender] = _amount;


        hasParticipated[msg.sender] = true;



    }

    function withdraw(IERC20 _tokenAddress) public{
        
        launchpad storage launch = launchpads[address(_tokenAddress)];
        uint256 userAmountMultiplier = launch.exchangeRatio;
        IERC20 token = launch.token;

        require(block.timestamp > launch.endTime, "LaunchPad hasn't ended");
        require(launch.isActive = false, "LauncPad has ended");
        require(hasParticipated[msg.sender] = true, "You didn't participate in this launchpad");

        uint256 userAmountToRecive = userContribution[msg.sender] * userAmountMultiplier;

        token.transfer(msg.sender, userAmountToRecive);

    }

    function withdrawRaisedFunds(IERC20 _token) external onlyOwner {
        launchpad storage tokenLaunch = launchpads[address(_token)];
        require(tokenLaunch.endTime < block.timestamp, "launchpad hasn't ended yet");

        uint256 totalRaised = tokenLaunch.totalRaised;
        uint256 platformFee = (totalRaised * 10) / 100; //platfrom percentage from raise
        uint256 amountToWithdrawAfterPlatformFee = totalRaised - platformFee;

        require(totalRaised > 0, "Unfortunatley, you didn't raise anything lmao");

        IERC20(_token).transfer(admin, platformFee);//withdraw platform fee for this particular token auction to the platform owner/team address
        IERC20(_token).transfer(tokenLaunch.projectOwner, amountToWithdrawAfterPlatformFee);//withdraw the rest to project owner address

        tokenLaunch.totalRaised = 0;//reset totalRaised;

        

    }





}
