const EtherSport =
  artifacts.require(`./EtherSport.sol`)

module.exports = (deployer) => {
  console.log('deployer.deploy', Object.keys(deployer))
  deployer.deploy(EtherSport,
      '0x21ec32c72c9976e7c1a52ec43c6158a7f24ccee1',
      1000000,
      44800,
      57600,
      57867,
      64267,
      108954,
      243018
  )
}
