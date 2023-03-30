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
        bool isActive;

    }

    mapping (address => launchpad) launchpads;

    constructor(address _nativeToken, address _admin) {
        nativeToken = IERC20(_nativeToken);
        admin = _admin;
    }

    function initiateTokenLaunch(address _token, uint256 _minDeposit, uint256 _maxDeposit, uint _totalAmountToBeDistributed, uint256 _exchangeRatio, uint256 _startTime, uint256 _endTime) external onlyOwner  {
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
        
    }

    function contribute(address _tokenToContribute, uint256 _amount) public {
        require(_tokenToContribute != address(0), "cannot contribute address zero");
        require(_amount != 0, "You seriously want to contribute 0? c'mon man");

        launchpad storage launch = launchpads[_tokenToContribute];

        require(launch.isActive = true, "Launcpad isn't active");
        require(_amount > launch.minDeposit, "Deposit amount is less than minimum Deposit for this token IFO");
        require(_amount <= launch.maxDeposit, "Amount is more than the maximum deposit amount");
        require(IERC20(_tokenToContribute) = launch.token, "Invalid token input");
    }





}
