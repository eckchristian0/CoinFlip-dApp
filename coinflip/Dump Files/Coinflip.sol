pragma solidity 0.5.12;
import "./Ownable.sol";
import "./provableAPI.sol";

contract CoinFlip is Ownable, usingProvable{

  //vaiables for API call
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  uint256 public latestNumber;

  //struct for accounts
  struct account{
    uint balance;
    bool gambling;
  }
  //mapping array to hold accounts
  mapping (address => account) public accounts;

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

  //calls update() at launch to get a random number initally
  constructor() public{
    update();
    accounts[msg.sender].balance = 0;
    accounts[msg.sender].gambling = false;
  }

  // funciton to add balance to a users account
  function fundAccount() public payable returns(uint){
    require(msg.value != 0);
    accounts[msg.sender].balance += msg.value;
    accounts[msg.sender].gambling = false;
    emit depositReceived(accounts[msg.sender].balance);
    return msg.value;
  }

  // function that takes users choice and amount to gamble, calls API, and pays out results
  function gamble(uint userCoinFacePick) public payable{
    // require the user to have enough funds
    require(accounts[msg.sender].balance >= msg.value, "Balance not Sufficient");
    //require users to pick a side of Coin
    require(userCoinFacePick <= 1 , "Must Choose Heads or Tails");
    //require user not to be gambling
    require(accounts[msg.sender].gambling != true);
    accounts[msg.sender].gambling = true;

    //integrate update funciton
    bytes32 _betID = update();

    //map bytes32 to bet and push to betsList
    betsPlaced[_betID].amountGambled = msg.value;
    betsPlaced[_betID].gambler = msg.sender;
    betsPlaced[_betID].gamblersPick = userCoinFacePick;
    betsPlaced[_betID].outcome = 10;
    new betsList.push(_betID);
  }

    //gets current users balance
    function checkBalance() public view returns(uint){
      return accounts[msg.sender].balance;
    }

    //allows user to withdraw funds
    function withdrawAll() public returns(uint){
      msg.sender.transfer(accounts[msg.sender].balance);
      accounts[msg.sender].balance = 0;
      return accounts[msg.sender].balance;
    }

    // Random Number Generator and Callback functions
    function __callback(bytes32 _queryID, string memory _result, bytes memory _proof) public{
      require(msg.sender == provable_cbAddress());
      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
      latestNumber = randomNumber;
      betsPlaced[_queryID].outcome = latestNumber;
      address gambler = betsPlaced[_queryID].gambler;
      accounts[gambler].gambling = false;
      //Take amount, coinFlip, and user choice to create Payout
      _Payout(_queryID);
      emit generateRandomNumber(randomNumber);
    }

  function update() public returns (bytes32){
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    bytes32 _queryID = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY,
      NUM_RANDOM_BYTES_REQUESTED,
      GAS_FOR_CALLBACK
      );
      emit logNewProvableQuery("Gamble added to queue, wait for CallBack");
      return _queryID;
    }

    //function that pays out based on results
    function _Payout(bytes32 _queryID) public returns(uint){
      uint256 amountGambled = betsPlaced[_queryID].amountGambled;
      if (betsPlaced[_queryID].gamblersPick == betsPlaced[_queryID].outcome){
        accounts[msg.sender].balance = accounts[msg.sender].balance + amountGambled;
        emit gambleWon(amountGambled, "Won");
      }
      if (betsPlaced[_queryID].gamblersPick != betsPlaced[_queryID].outcome){
        accounts[msg.sender].balance = accounts[msg.sender].balance - amountGambled;
        emit gambleLost(amountGambled, "Lost");
      }
      return (accounts[msg.sender].balance + amountGambled);

    }

    //allows js to get total bets placed to call
    function returnTotalBets() public view returns(uint){
      return betsList.length;
    }

    function currentlyGambling()public view returns(string memory){
      if(accounts[msg.sender].gambling == true){
        string memory x = "You Have a Bet Placed";
        return (x);
      }
      if (accounts[msg.sender].gambling == false){
        string memory y = "You Can Place a Bet";
        return (y);
      }
    }
}
