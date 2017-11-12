Project pages:
- [Main site](https://ethersport.io/)   
- [WhitePaper](https://ethersport.io/whitepaper.pdf)
- [BitcoinTalk](https://bitcointalk.org/index.php?topic=2297357)
- [Telegram channel](https://t.me/joinchat/HAJNAA4UJPyoNf0n4dpe0A)
- [Twitter](https://twitter.com/ethersport_esc)
- [Facebook](https://www.facebook.com/ethersport.io/)
- [Medium](https://medium.com/@ethersport)

Before all:
```
alias trpc='testrpc --mnemonic="curious elbow model rough february side fragile tree leave gas base dune" --account="0x764ce01d85034ba3f268b6b5556b77f2c678355a5774cdb259801f8affdf7263,1000000000000000000000000000000" --account="0x4c7cdb489021bd4183d66713b196992586edb0dc1a9f69ff30d1d24df74376ba,1000000" --account="0xd64dea487d529ebd1c0b38b6aa318d63e7f80d8a4abbb5206477f8d79b0424b9,1000000000000000000000000000000" --account="0x2c413af0b17d7fbdd38fdfa0286268d8125cc5339d9d3d1114b134208bd674b9,1000000000000000000000000000000" --account="0xd2875bfec9e5653a3adc621766c8ba81cb8ecd2e83b792d56fc16a27f6bc17df,1000000000000000000000000000000" --account="0xdb3e8526c0d041de44866e7efc4a009624cd0b9697841c6a0a60de1ae58f8066,1000000000000000000000000000000" --account="0x912da49ab4b6043d457a6111996918a8cd0d57aaa7994f28584396acbe2fcb41,0" --account="0x2055b84ef3b3c56e8337292c975eaca35e8040706956dcf4de14b52cbd43c9d3,0" --account="0xce8e34b3568cf5c8fdc7e41192597d4543ef0b0ebbf12f0530407f12e7315321,0" --account="0xa72b0b821f50cd872dfc64b6ee2320d8f8362f72f5baadf8ebe8f226a513e585,0" --account="0xa31fef424141fba3110cc87d777770758adb2afd8a2afcdf7f4fbc59d0c93854,0" --account="0xda1bbee92b61a612904bdd3a58ec3c39cf94f48e3372e4f0696b3d5b0b66d5ba,0" --account="0xe728c5dc42b281acdbf4aa0f4b69be3dabc72cfae3aa76c8df332c124993c179,0" --account="0x6b3ecc315b415125f062449cb39f3559d117fe0ae658df6ea47bc82ec4e8621c,0" --account="0x38448d51adb12212635ec2f7047f1beafe4168cbb4bb8c1218527cb561db6285,0" --account="0x1dd30b540773ca9bfa629718a3defa7bf9f1c04f05bb301f9e7c96ebe3b13774,0" --account="0x05cb70911d7d8d3ca61e28a43afd3fd7483ee6cc7a7de0a7cc32c27258d740bc,0" --account="0xe503c19ef84b52f1a23d15f0632ca3eb21ae9c5f0e660018f04fd6b6012a0a8e,0" --account="0x8ab1af71370eed1463eff5e0d35f64eba909d93308d7c457cd370b023301d4f2,0" --account="0x86549f8c57bf91e6569feb0fa5cb9afa4a04220f1008b7d4784fcafa5813767b,0"  '
npm install
```

Compile contract and migrate to network:
```
truffle compile
truffle migrate
```

Test smart contract:
```
trpc
truffle test
```