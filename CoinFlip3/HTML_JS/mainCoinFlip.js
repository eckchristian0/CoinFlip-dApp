var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){    //launches metamask to ask for connecting account
      //Contract(abi (create .js file to import),address(get from console migrate "string format"), from{account[0]})
      // The address supplied is the contract this will interact with
      contractInstance = new web3.eth.Contract(abi, "0x2Ef8Cd7B6733fd92cA525f0340d52B96197A8474", {from: accounts[0]});
      contractInstance.methods.checkBalance().call().then(function(res){
        $("#ETH_output").text(web3.utils.fromWei(res,"ether"))
      console.log(contractInstance);
      })
      //Variable for printing on html page
      contractInstance.methods.returnTotalBets().call().then(function(res){
        $("#Bets_Placed").text(res-1);
        })
/* Causing issue as Mapping is not working
      contractInstance.methods.currentlyGambling().call().then(function(res){
        console.log(res);
      })
*/

    $("#bet_heads").click(betOnHeads);
    $("#bet_tails").click(betOnTails);
    $("#deposit").click(fundAccount);
    $("#withdraw").click(withdrawAll);

    function betOnHeads() {
    var amountGambled = web3.utils.toWei($("#amountGambled_input").val(),"ether");
    contractInstance.methods.gamble(amountGambled, 0).send()
    .on("receipt", function(receipt){
    contractInstance.methods.checkBalance().call().then(function(res){
      $("#ETH_output").text(web3.utils.fromWei(res,"ether"))
      });
    })
      .on("receipt", function(receipt){
        contractInstance.methods.returnTotalBets().call().then(function(res){
          $("#Bets_Placed").text(res-1);
    });
    });
  };

    function betOnTails(){
      var amountGambled = web3.utils.toWei($("#amountGambled_input").val(),"ether")
      contractInstance.methods.gamble(amountGambled, 1).send()
      .on("receipt", function(receipt){
      contractInstance.methods.checkBalance().call().then(function(res){
        $("#ETH_output").text(web3.utils.fromWei(res,"ether"))
        });
      })
        .on("receipt", function(receipt){
          contractInstance.methods.returnTotalBets().call().then(function(res){
            $("#Bets_Placed").text(res-1);
      });
      });
    };

    function fundAccount(){
      var depAmount = $("#amountToDepWith_input").val();
      contractInstance.methods.fundAccount().send({value: web3.utils.toWei(depAmount)})
      .on("receipt", function(receipt){
      contractInstance.methods.checkBalance().call().then(function(res){
        $("#ETH_output").text(web3.utils.fromWei(res,"ether"));
      });
    });
  };

  function withdrawAll() {
    contractInstance.methods.withdrawAll().send({from: accounts[0]})
    .on("receipt", function(receipt){
    contractInstance.methods.checkBalance().call().then(function(res){
      $("#ETH_output").text(web3.utils.fromWei(res,"ether"));
      console.log("completed");//written to check if function was completed
    });
  });
  }

  //returns alert if gambler won
    contractInstance.events.gambleWon({fromBlock: 'latest'}, function(won){
      console.log("You Won ");
      alert("You Won");
  });

    //returns alert if gambler lost
      contractInstance.events.gambleLost({fromBlock: 'latest'}, function(lose){
      console.log("You were not a winner plese try another bet");
      alert("You were not a winner plese try another bet");
    });

    //returns alert depositReceived
      contractInstance.events.depositReceived({fromBlock: 'latest'}, function(funded){
      console.log(funded);
    });
  });
});
