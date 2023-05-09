// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

    /* Functionalities
        -- BET --
        placeBet(choice)
        payMe()
        checkStatus(address)

        -- Game --
        stopGame()
        resumeGame()
        endGame()
        cancelGame()
    */

contract BettingGame {
    address public owner;

    // a bet has a choice and an amount. Is it placed, and is it paid yet?
    struct Bet {
        int8 choice;
        uint256 amount;
        bool paid;
        bool placed;
    }
    mapping (address => Bet) bets;
    // Usage: bets[address].placed = true;

    // "game question; choice1; choice2", this-many-choices for the question, at least bet this much, you can bet more!

    string public game_desc; // contains multi-choice question and also choices delimited by ; in a single string
    int8 public no_of_choices; // 2, 3, 4, ? ; useful to parse $game_desc later.
    uint256 public min_bet_amount; // 1 ETH, 2 ETH, ?
    bool public allow_user_bet_amount; // I wanna bet more than minimum amount i.e. 5 ETH

    // one choice to rule 'em all
    int8 public correct_choice;
    string public correct_choice_txt; 
    
    // total bet-counts, bet-amounts
    int8 public total_bet_count;
    uint256 total_bet_amount;

    // total bet-amounts for each choice
    mapping(int8 => uint256) choice_bet_amounts;

    /* game status: 
        0 - not started (initial state)
        1 - started (once contract constructor runs)
        2 - stopped (stop bettings when a real match event starts)
        3 - ended (supply a correct choice after the match ends, to end the bets)
        4 - cancelled (allow refunds for every bettor)
    */
    int8 game_status;

    modifier onlyOwner() {
        assert(msg.sender == owner); // only owner can start, stop, end or cancel a game
        _;
    }

    // a constructor begins a betting game
    constructor(string memory _game_desc, int8 _no_of_choices, uint256 _min_bet_amount, bool _allow_user_bet_amount) public {
        // pre-requisites ;;
        require(_no_of_choices > 0);
        require(_min_bet_amount > 0);

        owner = msg.sender;

        game_status = 1; // game begins here --
        game_desc = _game_desc;
        no_of_choices = _no_of_choices;
        min_bet_amount = _min_bet_amount;
        allow_user_bet_amount = _allow_user_bet_amount;

        total_bet_count = 0;
        total_bet_amount = 0;
        correct_choice = -1; // until game ends, not a valid choice
        correct_choice_txt = ""; // none yet!
    }


    function placeBet (int8 _choice) public payable {
        require (game_status == 1); // game is running
        require (_choice <= no_of_choices); // Valid choice
        require (msg.value >= min_bet_amount); // Meet min bet amount
        require (bets[msg.sender].placed == false); // Only bet once

        Bet memory newBet = Bet(_choice, msg.value, false, true);
        bets[msg.sender] = newBet;

        choice_bet_amounts[_choice] = choice_bet_amounts[_choice] + msg.value;
        total_bet_amount = total_bet_amount + msg.value;
        total_bet_count += 1;
    }

    function stopGame() external onlyOwner {
        require (game_status == 1);
        game_status = 2;
    }

    function resumeGame() external onlyOwner {
        require (game_status == 2);
        game_status = 1;
    }

    function endGame(int8 _correct_choice, string memory _correct_choice_txt)
          external onlyOwner {
        correct_choice = _correct_choice;
        correct_choice_txt = _correct_choice_txt;
        game_status = 3;
    }

    function cancelGame() public {
        require (msg.sender == owner);
        game_status = 4;
    }
    
    function payMe () public {
        require (bets[msg.sender].placed); // Must have a bet
        require (bets[msg.sender].amount > 0); // More than zero
        require (bets[msg.sender].paid == false); // chose correctly

        if (game_status == 3) {
            // game ended normally
            require (bets[msg.sender].choice == correct_choice);
            uint256 payout = bets[msg.sender].amount * total_bet_amount /
            choice_bet_amounts[correct_choice];
            if (payout > 0) {
                msg.sender.transfer(uint256(payout));
                bets[msg.sender].paid = true; // cannot claim twice
            }
        } else if (game_status == 4) {
            // Just refund the bet
            msg.sender.transfer(uint256(bets[msg.sender].amount));
            bets[msg.sender].paid = true; // cannot claim twice
        } else {
            require (false); // Just fail
        }
    }

    function checkStatus (address _addr) public view returns (int8, string memory,
        int8, uint256, uint256, bool, int8) {
        uint256 payout = 0;
        if (game_status == 3 && bets[_addr].choice == correct_choice) {
            payout = bets[_addr].amount * total_bet_amount / choice_bet_amounts[correct_choice];
        } else if (game_status == 4) {
            payout = bets[_addr].amount;
        }
        return (game_status, game_desc, bets[_addr].choice,
        uint256(bets[_addr].amount), payout,
        bets[_addr].paid, correct_choice);
    }

    function getBetInfo()public view returns(int8, string memory,int8,int8,uint256,bool){
        return (game_status, game_desc, correct_choice, total_bet_count,
          total_bet_amount, allow_user_bet_amount);
    }

    function getAnswer() public view returns (int8, string memory) {
        return (correct_choice, correct_choice_txt);
    }

    function terminate() external onlyOwner {
        selfdestruct(payable(owner));
    }
}
