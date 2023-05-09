App = {
  web3Provider: null,
  contracts: {},
  networkId: null,

  init: function () {
    return App.initWeb3();
  },

  // Instance Web3
  initWeb3: async function () {
    // Is there an injected web3 instance?
    if (typeof web3 !== "undefined") {
    } else {
      // If no injected web3 instance is detected, fall back to Ganache
      // Only useful in a development environment
      App.networkId = 5777;
      App.web3Provider = new Web3.providers.HttpProvider(
        "http://localhost:7545"
      );
    }
  },

  connectWallet: async function () {
    await window.ethereum.enable();
  },

  // Instance contract
  initContract: function () {
    return App.bindEvents();
  },

  getAccount: async function () {},

  getAllProposals: async function () {
    let instance = App.contracts.Voting.instance;
    // get the total number of proposals

    let wrapperProposals = $("#wrapperProposals");
    wrapperProposals.empty();
    let proposalTemplate = $("#proposalTemplate");

    for (var i = 0; i < numProposals; i++) {
      // get the proposal detail

      var idx = data[0];
      proposalTemplate.find(".title").text(data[1]);
      proposalTemplate.find(".proposed-by").text(data[2]);
      proposalTemplate.find(".numVotesPos").text(data[3]);
      proposalTemplate.find(".numVotesNeg").text(data[4]);
      proposalTemplate.find(".btn-vote").attr("data-proposal", idx);
      proposalTemplate.find(".btn-vote").attr("disabled", false);
      // get the voter status

      // if (voterStatus) {
      //   proposalTemplate.find(".btn-vote").attr("disabled", true);
      // }
      wrapperProposals.append(proposalTemplate.html());
    }
  },

  getVoterStatus: async function (proposalId) {},

  handleAddProposal: async function (event) {
    event.preventDefault();
    // let instance = App.contracts.Voting.instance;
    // let value = $(".input-value").val();
    // let account = await App.getAccount();
    // if (value === "") {
    //   $(".toast").toast("show");
    //   return;
    // }
  },

  handleAddVote: async function (event) {
    // event.preventDefault();
    // let instance = App.contracts.Voting.instance;
    // let voteValue = $(event.target).data("vote");
    // let proposalInt = parseInt($(event.target).data("proposal"));
    // let account = await App.getAccount();
  },

  bindEvents: function () {
    $(document).on("click", "#btn-connect", async function (e) {
      let $this = $(this);
      App.btnLoading($this, "Connecting...");
      try {
        await App.connectWallet(e);
        await App.initWeb3();
      } catch (e) {
        App.btnReset($this);
      }
      App.btnReset($this);
    });
    $(document).on("click", ".btn-value", async function (e) {
      let $this = $(this);
      App.btnLoading($this);
      try {
        await App.handleAddProposal(e);
      } catch (e) {
        App.btnReset($this);
      }
      App.btnReset($this);
    });

    $(document).on("click", ".btn-vote", async function (e) {
      var $this = $(this);
      App.btnLoading($this);
      try {
        await App.handleAddVote(e);
      } catch (e) {
        App.btnReset($this);
      }
      App.btnReset($this);
    });

    window.ethereum.on("accountsChanged", function (account) {
      App.getAllProposals();
    });
  },

  btnLoading: function (elem, message) {
    $(elem).attr("data-original-text", $(elem).html());
    $(elem).prop("disabled", true);
    $(elem).html(
      `<i class="spinner-border spinner-border-sm"></i> ${
        message || "Processing..."
      }`
    );
  },

  btnReset: function (elem) {
    $(elem).prop("disabled", false);
    $(elem).html($(elem).attr("data-original-text"));
  },
};

$(function () {
  $(window).load(function () {
    App.init();
  });
});
