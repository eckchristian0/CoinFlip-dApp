pragma solidity 0.5.12;
import "./ownable.sol";
import "./ProvableAPI.sol";

contract CoinFlip is usingProvable{

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
    bytes32 _queryID;
    uint256 amountGambled;
    address gambler;
    uint gamblersPick;
    uint256 outcome;
  }

  //mapping for users balance and connecting _queryIDs to bets, struct to enumerate list of bets
  mapping (uint => bet) public betsPlaced;
  uint[] public betsList;


  //events for each function
  event logNewProvableQuery(string description); //update
  event gambleWon(uint amount, string marker); //_Payout
  event gambleLost(uint amount, string marker); //_payout

  //calls update() at launch to get a random number initally
    constructor() public{
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].gambling = false;
    }

    // function that takes users choice and amount to gamble, calls API, and pays out results
  function gamble(uint userCoinFacePick) payable public {
    uint256 amountGambled = msg.value;
    //require users to pick a side of Coin
    require(userCoinFacePick <= 1 , "Must Choose Heads or Tails");
    //require user not to be gambling
    require(accounts[msg.sender].gambling != true);
    accounts[msg.sender].gambling = true;

    //integrate update funciton
    update(amountGambled, userCoinFacePick);
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
     //Get betID for payout function
      uint __betID = getBetID(_queryID);
      betsPlaced[__betID].outcome = latestNumber;
      address gambler = betsPlaced[__betID].gambler;
      accounts[gambler].gambling = false;
      //Take amount, coinFlip, and user choice to create Payout
      _Payout(_queryID);
    }


    function update(uint256 amountGambled, uint userCoinFacePick) public payable{
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 250000;
        bytes32 _queryID = provable_newRandomDSQuery(
          QUERY_EXECUTION_DELAY,
          NUM_RANDOM_BYTES_REQUESTED,
          GAS_FOR_CALLBACK
          );
          //map bytes32 to bet and push to betsList
          uint betIDNumber = betsList.length;
          betsPlaced[betIDNumber].amountGambled = msg.value;
          betsPlaced[betIDNumber]._queryID = _queryID;
          betsPlaced[betIDNumber].gambler = msg.sender;
          betsPlaced[betIDNumber].gamblersPick = userCoinFacePick;
          betsList.push(betIDNumber);
          emit logNewProvableQuery("Gamble added to queue, wait for CallBack");
        }

    //function that pays out based on results
    function _Payout(bytes32 _queryID) public returns(uint){
      uint __betID = getBetID(_queryID);
      uint256 amountGambled = betsPlaced[__betID].amountGambled;
      if (betsPlaced[__betID].gamblersPick == betsPlaced[__betID].outcome){
        accounts[msg.sender].balance = accounts[msg.sender].balance + (amountGambled * 2);
        emit gambleWon(amountGambled, "Won");
      }
      if (betsPlaced[__betID].gamblersPick != betsPlaced[__betID].outcome){
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

    function getBetID(bytes32 _queryID) private view returns(uint){
        for(uint i=0; i>=betsList.length; i++){
            if(betsPlaced[betsList[i]]._queryID == _queryID){
                return i;
            }
        }
    }

    function totalWinnings() external view returns(uint256){
       uint256 Winnings = 1;
       if(betsList.length == 0){
         return 0;
       }
       else{
         for(uint i = 0 ; i<betsList.length; i++){
            if(betsPlaced[betsList[i]].gamblersPick == betsPlaced[betsList[i]].outcome){
               Winnings += betsPlaced[betsList[i]].amountGambled;
            }
        }
        return Winnings;
    }
  }
}
