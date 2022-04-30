//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //mapping token address -> staker address -> amount

    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenToPriceFeedMapping;
    address[] public stakers;


    address[] public allowedTokens;
    IERC20 public dappToken;


    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token,address _priceFeed) public onlyOwner {
        tokenToPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        for(uint256 stakersIndex=0;stakersIndex<stakers.length;stakersIndex++){
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient,userTotalValue);

        }
    }
    function getUserTotalValue(address _user) public view returns (uint256){
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0,"No tokens staked");
        for (uint256 allowedTokensIndex =0; allowedTokensIndex < allowedTokens.length;allowedTokensIndex++){
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }


    function getUserSingleTokenValue(address _user,address _token) public view returns(uint256){
        if(uniqueTokensStaked[_user]<=0){
            return 0;
        }
        (uint256 price,uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price /(10**decimals));
    }

    function getTokenValue(address _token) public view returns (uint256,uint256) {
        address priceFeedAddress = tokenToPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price),decimals);


    }



    function stakeTokens(uint256 _amount,address _token) public {
        require(_amount > 0,"AMount must be more than 0");
        require(tokenIsAllowed(_token),"Token is currently not allowed");
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender]= stakingBalance[_token][msg.sender]+ _amount;
        if(uniqueTokensStaked[msg.sender]==1){
            stakers.push(msg.sender);
        }


    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0,"Staking balance cannot be 0 ");
        IERC20(_token).transfer(msg.sender,balance);
        stakingBalance[_token][msg.sender]=0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender]-1;

    }

    function updateUniqueTokensStaked(address user,address token) internal {
        if(stakingBalance[token][user]<=0){
            uniqueTokensStaked[user]= uniqueTokensStaked[user]+1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool){
        for(uint256 allowedTokensIndex =0; allowedTokensIndex < allowedTokens.length;allowedTokensIndex++){
            if (allowedTokens[allowedTokensIndex]==_token){
                return true;
            }
        }
        return false;

    }
}