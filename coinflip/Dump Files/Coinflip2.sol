/*
pragma solidity 0.5.12;
import "./Ownable.sol";
import "./provableAPI.sol";

contract CoinFlip is Ownable, usingProvable{

  //vaiables for API call
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  uint256 public latestNumber;

  mapping (address => uint) public person;
  mapping (address => bool) public gambling;

  //struct to hold the information on bets
  struct bet{
    uint256 amountGambled;
    address gambler;
    uint gamblersPick;
    uint256 outcome;
  }

  //mapping for users balance and connecting _queryIDs to bets, struct to enumerate list of bets
  mapping (bytes32 => bet) public betsPlaced;
  bytes32[] public betsList;


  //events for each function
  event depositReceived(uint funds); //fundAccount
  event logNewProvableQuery(string description); //update
  event generateRandomNumber(uint256 randomNumber); //__callback
  event gambleWon(uint amount, string marker); //_Payout
  event gambleLost(uint amount, string marker); //_payout
  event test(uint256 amount);

  //calls update() at launch to get a random number initally
  constructor() public{
    update(0,2);
    balance[msg.sender] = 0;
    gambling[msg.sender] = false;
  }

  // funciton to add balance to a users account
  function fundAccount() public payable returns(uint){
    require(msg.value != 0);
    balance[msg.sender] += msg.value;
    return msg.value;
  }

  // function that takes users choice and amount to gamble, calls API, and pays out results
  function gamble(uint amountGambled, uint userCoinFacePick) public {
    // require the user to have enough funds
    require(balance[msg.sender] >= amountGambled, "Balance not Sufficient");
    //require users to pick a side of Coin
    require(userCoinFacePick <= 1 , "Must Choose Heads or Tails");
    //require user not to be gambling
    require(gambling[msg.sender] != true);
    address gambler = msg.sender;
    gambling[gambler] = true;

    //integrate update funciton
    update(amountGambled, userCoinFacePick);
  }

    //gets current users balance
    function checkBalance() public view returns(uint){
      return balance[msg.sender];
    }

    //allows user to withdraw funds
    function withdrawAll() public returns(uint){
      msg.sender.transfer(balance[msg.sender]);
      balance[msg.sender] = 0;
        return balance[msg.sender];
    }

    // Random Number Generator and Callback functions
    function __callback(bytes32 _queryID, string memory _result, bytes memory _proof) public{
      require(msg.sender == provable_cbAddress());
      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
      latestNumber = randomNumber;
      betsPlaced[_queryID].outcome = latestNumber;
      address gambler = betsPlaced[_queryID].gambler;
      gambling[gambler] = false;
      //Take amount, coinFlip, and user choice to create Payout
      _Payout(_queryID);
      emit generateRandomNumber(randomNumber);
    }

  function update(uint256 amountGambled, uint userCoinFacePick) public payable{
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    bytes32 _queryID = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY,
      NUM_RANDOM_BYTES_REQUESTED,
      GAS_FOR_CALLBACK
      );
      //map bytes32 to bet and push to betsList
      betsPlaced[_queryID].amountGambled = amountGambled;
      betsPlaced[_queryID].gambler = msg.sender;
      betsPlaced[_queryID].gamblersPick = userCoinFacePick;
      betsPlaced[_queryID].outcome = 10;
      betsList.push(_queryID);
      emit logNewProvableQuery("Gamble added to queue, wait for CallBack");
    }

    //function that pays out based on results
    function _Payout(bytes32 _queryID) public returns(uint){
      uint256 amountGambled = betsPlaced[_queryID].amountGambled;
      if (betsPlaced[_queryID].gamblersPick == betsPlaced[_queryID].outcome){
        balance[msg.sender] = balance[msg.sender] + amountGambled;
        emit gambleWon(amountGambled, "Won");
      }
      if (betsPlaced[_queryID].gamblersPick != betsPlaced[_queryID].outcome){
        balance[msg.sender] = balance[msg.sender] - amountGambled;
        emit gambleLost(amountGambled, "Lost");
      }
      emit test(amountGambled);
      return (balance[msg.sender] + amountGambled);

    }

    //allows js to get total bets placed to call
    function returnTotalBets() public view returns(uint){
      return betsList.length;
    }

    function currentlyGambling()public view returns(string memory){
      if(gambling[msg.sender] == true){
        string memory x = "Are";
        return (x);
      }
      if (gambling[msg.sender] == false){
        string memory y = "Are Not";
        return (y);
      }

    }
}
