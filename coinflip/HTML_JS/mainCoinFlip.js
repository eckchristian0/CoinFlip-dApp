var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){    //launches metamask to ask for connecting account
      //Contract(abi (create .js file to import),address(get from console migrate "string format"), from{account[0]})
      // The address supplied is the contract this will interact with
      contractInstance = new web3.eth.Contract(abi, "0x578d29D88Ff8584837eA9136DDE05a5443A80380", {from: accounts[0]});
      contractInstance.methods.checkBalance().call().then(function(res){
        $("#ETH_output").text(web3.utils.fromWei(res,"ether"))
      console.log(contractInstance);
      })
      //Variable for printing on html page
      contractInstance.methods.returnTotalBets().call().then(function(res){
        $("#Bets_Placed").text(res);
        })
      // Shows if player is currentlyGambling
      contractInstance.methods.currentlyGambling().call().then(function(res){
      $("#gambling").text(res);
      })
      contractInstance.methods.totalWinnings().call().then(function(res){
        $("#Winnings").text(parseFloat(web3.utils.fromWei(res,"ether")));
      })

    $("#bet_heads").click(betOnHeads);
    $("#bet_tails").click(betOnTails);
    $("#withdraw").click(withdrawAll);

    function betOnHeads() {
    var amountGambled = web3.utils.toWei($("#amountGambled_input").val(),"ether");
    contractInstance.methods.gamble(0).send({value:amountGambled})
    .on("receipt", function(receipt){
    contractInstance.methods.currentlyGambling().call().then(function(res){
      $("#gambling").text(res);
    });
  })
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
      contractInstance.methods.gamble(1).send({value:amountGambled, gas: 500000})
      .on("receipt", function(receipt){
      contractInstance.methods.currentlyGambling().call().then(function(res){
        $("#gambling").text(res);
      });
    })
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

  function withdrawAll() {
    contractInstance.methods.withdrawAll().send({from: accounts[0]})
    .on("receipt", function(receipt){
    contractInstance.methods.checkBalance().call().then(function(res){
      $("#ETH_output").text(web3.utils.fromWei(res,"ether"));
      console.log("Completed Withdraw");//written to check if function was completed
    });
  });
  }

  //returns alert if gambler won
    contractInstance.events.gambleWon({fromBlock: 'latest'}, function(won){
      console.log("You Won ");
      alert("You Won");
      contractInstance.methods.currentlyGambling().call().then(function(res){
        $("#gambling").text(res);
      });
      contractInstance.methods.checkBalance().call().then(function(res){
        $("#ETH_output").text(web3.utils.fromWei(res,"ether"));
      });
    })

    //returns alert if gambler lost
      contractInstance.events.gambleLost({fromBlock: 'latest'}, function(lose){
      console.log("You were not a winner plese try another bet");
      alert("You were not a winner plese try another bet");
      contractInstance.methods.currentlyGambling().call().then(function(res){
        $("#gambling").text(res);
      });
      contractInstance.methods.checkBalance().call().then(function(res){
        $("#ETH_output").text(web3.utils.fromWei(res,"ether"));
      });  
    });
  });
});
