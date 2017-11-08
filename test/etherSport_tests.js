const _ = require('underscore')
const expectThrow = require('./utils').expectThrow

const EtherSport = artifacts.require('EtherSport')


let instance
let _startBlock
let _owner
let _ethFundAddress
let _other
let _defaultBlockHeightDiff = [44800,    57600, 57867, 64267, 108954,    243018]
let _oneBlockHeightDiff = [1,    2, 2, 3, 4,    5]


const customContractFunctionCall = (_userAddress, _func, _funcData, _wei, asyncCallback) => new Promise((resolve, reject) => {
    const contractAbi = web3.eth.contract(instance.abi);
    const myContract = contractAbi.at(instance.address);
    //finally pass this data parameter to send Transaction
    console.log('going to', _funcData !== "___empty___" ? 'call fn with args: '+JSON.stringify(_funcData) : 'send eth', _userAddress, 'to', instance.address);
    // suppose you want to call a function named myFunction of myContract
    let getData;
    if(_funcData === '___empty___') {
        getData = myContract[_func].getData();
    } else {
        getData = myContract[_func].getData(..._funcData)
    }

    web3.eth.sendTransaction({
        to: instance.address,
        from: _userAddress,
        data: getData,
        value: _wei,
        gas: 3000000
    }, async (err, transactionHash) => {
        asyncCallback(err, resolve, reject)
    });
})

const asyncBlank =  async (err, resolve, reject) => {
    if (err) return reject(err)
    resolve();
}
contract('EtherSport', function (accounts) {
    console.log('=contract EtherSport accounts:', accounts)

    _owner = accounts[0]
    _ethFundAddress = accounts[1]
    _other = accounts[2]

    beforeEach(async () => {
        _startBlock = web3.eth.getBlock('latest').number+2;
        instance = await EtherSport.new(accounts[1],_startBlock, ..._defaultBlockHeightDiff);
    })

    it('creation: check static data', async () => {
        let name      = await instance.name.call();
        let symbol    = await instance.symbol.call();
        let decimals  = await instance.decimals.call();
        let tokenUnit = await instance.tokenUnit.call();
        let owner = await instance.owner.call();
        let ethFundAddress = await instance.ethFundAddress.call();
        assert.strictEqual(name, "Ether Sport");
        assert.strictEqual(symbol, "ESC");
        assert.strictEqual(decimals.toNumber(), 18);
        assert.strictEqual(+web3.fromWei(tokenUnit.toNumber()), 1); //The same as ether
        assert.strictEqual(owner, _owner); // We must be sure that owner set properly
        assert.strictEqual(ethFundAddress, _ethFundAddress);
    })

    it('creation: should fail if start block already minded', async () => {
        return expectThrow(EtherSport.new(accounts[1],1, ..._defaultBlockHeightDiff));
    })

    it('creation: should fail if fund address is 0x0', async () => {
        return expectThrow(EtherSport.new(0x0,100000, ..._defaultBlockHeightDiff));
    })

    it('stopSale: should stop sale if contact creator ask', async () => {
        let isStopped = await instance.isStopped.call();
        assert.strictEqual(isStopped, false)
        return customContractFunctionCall(_owner, 'stopSale', '___empty___', 0,
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let isStopped = await instance.isStopped.call();
                assert.strictEqual(isStopped, true)
                resolve();
            }
        )
    })

    it('stopSale: should not stop sale if any person ask(not creator)', async () => {
        let isStopped = await instance.isStopped.call();
        assert.strictEqual(isStopped, false)
        return expectThrow(customContractFunctionCall(_other, 'stopSale', '___empty___', 0, asyncBlank))
    })

    it('stopSale: should restart sale if contact creator ask', async () => {
        let isStopped = await instance.isStopped.call();
        assert.strictEqual(isStopped, false)
        return customContractFunctionCall(_owner, 'stopSale', '___empty___', 0,
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let isStopped = await instance.isStopped.call();
                assert.strictEqual(isStopped, true)
                await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0,
                    async (err, resolve, reject) => {
                        if (err) return reject(err)
                        let isStopped = await instance.isStopped.call();
                        assert.strictEqual(isStopped, false)
                        resolve()
                    }
                )
                resolve()
            }
        )
    })

    it('stopSale: should restart sale if any person ask(not creator)', async () => {
        let isStopped = await instance.isStopped.call();
        assert.strictEqual(isStopped, false)
        return customContractFunctionCall(_owner, 'stopSale', '___empty___', 0,
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let isStopped = await instance.isStopped.call();
                assert.strictEqual(isStopped, true)
                await expectThrow(customContractFunctionCall(_other, 'restartSale', '___empty___', 0, asyncBlank))
                resolve()
            }
        )
    })

    it('changeOwner: should change owner of contract', async () => {
        return customContractFunctionCall(_owner, 'changeOwner', [_other], 0,
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let owner = await instance.owner.call();
                assert.strictEqual(owner, _other); // We must be sure that owner set properly
                resolve();
            }
        )
    })

    it('claimTokens: should reject payment under min payment value', async () => {
        return expectThrow(customContractFunctionCall(_other, 'claimTokens', '___empty___', 1, asyncBlank))
    })

    it.only('claimTokens: should purchases tokens', async () => {
        return customContractFunctionCall(_other, 'claimTokens', '___empty___',
            web3.toWei(1),
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let _otherBalance = await instance.balanceOf.call(_other);
                assert.strictEqual(+web3.fromWei(_otherBalance), 2000); // We must be sure that owner set properly
                resolve();
            }
        )
    })

    it('claimTokens: should reject payment more that period cap (pre-ico)',  async () => {
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        return expectThrow(customContractFunctionCall(_other, 'claimTokens', '___empty___', web3.toWei(5001), asyncBlank))
    })

    it('claimTokens: should reject payment until token sale started', async () => {
        _startBlock = web3.eth.getBlock('latest').number+10;
        instance = await EtherSport.new(accounts[1],_startBlock, ..._defaultBlockHeightDiff);
        return expectThrow(customContractFunctionCall(_other, 'claimTokens', '___empty___', web3.toWei(0.0005), asyncBlank))
    })

    it('claimTokens: should reject payment after token sale finished by time', async () => {
        _startBlock = web3.eth.getBlock('latest').number+2;
        instance = await EtherSport.new(accounts[1],_startBlock, ..._oneBlockHeightDiff);
        //mine 5 block by simple tx
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        // try to fund after sale is close
        return expectThrow(customContractFunctionCall(_other, 'claimTokens', '___empty___', web3.toWei(0.0005),
            async (err, resolve, reject) => {
                if (err) return reject(err)
                resolve();
            }
        ))
    })

    it('claimTokens: should reject payment if token sale stopped', async () => {
        let isStopped = await instance.isStopped.call();
        assert.strictEqual(isStopped, false)
        return customContractFunctionCall(_owner, 'stopSale', '___empty___', 0,
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let isStopped = await instance.isStopped.call();
                assert.strictEqual(isStopped, true)
                await expectThrow(customContractFunctionCall(_other, 'claimTokens', '___empty___', 1,
                    async (err, resolve, reject) => {
                        if (err) return reject(err)
                        resolve();
                    }
                ))
                resolve();
            }
        )
    })

    it('finalize: should reject finalize if token sale going on', async () => {
        return expectThrow(customContractFunctionCall(_owner, 'finalize', '___empty___', 0, asyncBlank))
    })

    it('finalize: should reject finalize if token sale finished by time for not owner', async () => {
        _startBlock = web3.eth.getBlock('latest').number+2;
        instance = await EtherSport.new(accounts[1],_startBlock, ..._oneBlockHeightDiff);
        //skip 1 block
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        // buy tokens for 1 ETH
        await customContractFunctionCall(_other, 'claimTokens', '___empty___',
            web3.toWei(1),
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let _otherBalance = await instance.balanceOf.call(_other);
                assert.strictEqual(+web3.fromWei(_otherBalance), 2000); // We must be sure that owner set properly
                resolve();
            }
        )
        //skip 3 more block
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        //finalise
        return expectThrow(customContractFunctionCall(_other, 'finalize', '___empty___', 0, asyncBlank))
    })

    it('finalize: should reject finalize if token sale finished by time', async () => {
        _startBlock = web3.eth.getBlock('latest').number+2;
        instance = await EtherSport.new(accounts[1],_startBlock, ..._oneBlockHeightDiff);
        //skip 1 block
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        // buy tokens for 1 ETH
        await customContractFunctionCall(_other, 'claimTokens', '___empty___',
            web3.toWei(1),
            async (err, resolve, reject) => {
                if (err) return reject(err)
                let _otherBalance = await instance.balanceOf.call(_other);
                assert.strictEqual(+web3.fromWei(_otherBalance), 2000); // We must be sure that owner set properly
                resolve();
            }
        )
        //skip 3 more block
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        await customContractFunctionCall(_owner, 'restartSale', '___empty___', 0, asyncBlank)
        //finalise
        return customContractFunctionCall(_owner, 'finalize', '___empty___', 0, asyncBlank)
    })
})
