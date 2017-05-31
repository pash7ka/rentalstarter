pragma solidity ^0.4.11;

import './zeppelin.sol';

/**
 * @title RentalStarterProfitToken
 * @dev Token for a RentalStarter project
 */
contract RentalStarterProfitToken is StandardToken {
    using SafeMath for uint;
    
    /**
    * Standart token constants
    */
    string public name = "RentalStarterProfitToken";
    string public symbol = "RSPT";
    uint public decimals = 8;

    /**
    * Inherited variables
    */
    // uint public totalSupply;
    // mapping(address => uint) balances;

    /**
    * State variables
    */
    address founder;                //owner of a contract
    bool public disabled = false;   //for migrations purposes contract may be disabled

    /**
    * @dev Modifier throws if called by any account other than the founder. 
    */
    modifier onlyFounder() {
        if (msg.sender != founder) throw;
        _;
    }
    /**
    * @dev Modifier throws if contract is 
    */
    modifier isActive() {
        if (disabled) throw;
        _;
    }

    /**
    * @dev Fallback function used to send dividends to a contract
    */
    function () payable isActive {
        //We want to allow payments fom exchange, so we have to keep it cheap
    }

    /**
    * @dev Fired when a holder redeems his tokens
    * @param holder address of token holder
    * @param tokens amount of redeemed tokens
    * @param value amount of redeemed ether
    */
    event RedeemProfit(address indexed holder, uint tokens, uint value);

    /**
    * @dev Creates a contract and assigns initial tokens to their holders
    * @param _initialHolders List of initial holders
    * @param _initialBalances List of initial balances
    */
    function RentalStarterProfitToken(address[] _initialHolders, uint[] _initialBalances) {
        assert(_initialHolders.length == _initialBalances.length);
        founder = msg.sender;
        totalSupply = 0;
        for(uint i=0; i < _initialHolders.length; i++){
            address holder = _initialHolders[i];
            uint tokens = _initialBalances[i];
            if(tokens > 0) {
                balances[holder] = tokens;
                totalSupply.add(tokens);
            }
        }
    }

    /**
    * @dev Redeem profit for tokens
    * @param _tokens amount of to redeem
    */
    function redeemProfit(uint _tokens) onlyPayloadSize(2*32) isActive {
        uint holderBalance = balances[msg.sender];
        assert(holderBalance >= _tokens);
        assert(this.balance > 0); //if we have no ether tokens can't be redeemed
        
        //uint value = _tokens.mul(profitPerToken());   //amount of ether to redeem
        uint value = (this.balance.mul(_tokens)).div(totalSupply); //make sure to multiply first, then divide
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        msg.sender.transfer(value);           //transfer will throw on error and revert state if failed
        RedeemProfit(msg.sender, _tokens, value);
    }

    /**
    * @dev Calculate profit per token
    */
    function profitPerToken() constant returns (uint value) {
        value = this.balance.div(totalSupply);
    }

    /**
    * @dev disable contract and send all remaining ether back
    * This may be used for migration to a new version
    */
    function disable() public onlyFounder {
        disabled = true;
        msg.sender.transfer(this.balance);
    }


    /**
    * Overload standart functions to allow transfers only if active
    */
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) isActive {
        super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) isActive {
        super.transferFrom(_from, _to, _value);
    }



    function assert(bool assertion) internal {
        if (!assertion) throw;
    }

}
