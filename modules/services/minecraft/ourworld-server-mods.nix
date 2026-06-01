# Generated from the Prism ourworld server-side mod selection.
# Mirrors the nix-minecraft symlinks.mods/linkFarmFromDrvs pattern for Our World.
{pkgs}: {
  # AppleSkin 3.0.8+mc1.21.11 (required)
  appleskin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/59ti1rvg/appleskin-fabric-mc1.21.11-3.0.8.jar";
    sha512 = "d32206cb8d6fac7f0b579f7269203135777283e1639ccb68f8605e9f5469b5b54305fd36ba82c64b48b89ae4f1a38501bfb5827284520c3ec622d95edcfa34de";
  };

  # Balm 21.11.9+fabric-1.21.11 (required)
  balm = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/MBAkmtvl/versions/wk8IL07y/balm-fabric-1.21.11-21.11.9.jar";
    sha512 = "42c894cf4d8d5f89d1806aa397f939d8ce75e079ce0c21f5a4720023eb64c861585e2b3d1ab50e4487b3e88612b03e31e09f70915093ba291d80349fcd0d56d5";
  };

  # Carry On 2.9.0 (required)
  carry_on = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/joEfVgkn/versions/twgpqIAS/carryon-fabric-1.21.11-2.9.0.jar";
    sha512 = "2a73c5a12898ba2c613afe1a9dec559011946b4b7b1338328d4c279a7cb921be6c8c9789c1b35037a0aa826eb27efa1a45090d28fd27bf7dffd3bacebab4c676";
  };

  # Chunky 1.4.55 (required)
  chunky = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fALzjamp/versions/1CpEkmcD/Chunky-Fabric-1.4.55.jar";
    sha512 = "3be0e049e3dea6256b395ccb1f7dccc9c6b23cb7b1f6a717a7cd1ca55f9dbda489679df32868c72664ebb28ca05f2c366590d1e1a11f0dc5f69f947903bad833";
  };

  # Cloth Config v20 21.11.153+fabric (required)
  cloth_config = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/9s6osm5g/versions/xuX40TN5/cloth-config-21.11.153-fabric.jar";
    sha512 = "8f455489d4b71069e998568cf4e1450116f4360a4eb481cd89117f629c6883164886cf63ca08ac4fc929dd13d1112152755a6216d4a1498ee6406ef102093e51";
  };

  # Concurrent Chunk Management Engine 0.3.7+alpha.0.10+1.21.11 (required)
  c2me = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/VSNURh3q/versions/UeCYljaE/c2me-fabric-mc1.21.11-0.3.7%2Balpha.0.10.jar";
    sha512 = "2bec8077fc0209082776730b183633f08e328e570ecea9b3095bded6b09526cb694d0165046538c13f456e67c66895cd4dc2cebf91e2588f1cca76dc522b9962";
  };

  # Create Fly 1.21.11-6.0.9-5 (required)
  create_fly = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/dKvj0eNn/versions/fn0H9rSj/create-fly-1.21.11-6.0.9-5.jar";
    sha512 = "c6cea5fa765ed8901cbb1ea83d9f58ffcdf99ff70e0912bbfb6ef3cca7c253b4257cbca6e0fc9bcf123a003ea3ea8f9a3654326bc1e243bbcb34a9af47fcc92b";
  };

  # CreativeCore 2.14.11 (required)
  creativecore = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/OsZiaDHq/versions/jyLHWJlj/CreativeCore_FABRIC_v2.14.11_mc1.21.11.jar";
    sha512 = "f30d3ca11a53a74043010c9c8c2a470de708030c12d325a00b317d72357dc2c250eb0de6ca78bf7f5ba0257a13b61f4a79580b3b92a13ae1b6a8441c5adb76a5";
  };

  # Cristel Lib fabric-1.21.11-3.1.2 (required)
  cristel_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/cl223EMc/versions/yWdD26Oh/cristellib-fabric-1.21.11-3.1.2.jar";
    sha512 = "39b55242591208c3c1bbd0eb0c4fe719cdf1bd9356146bd1712af9a35f0765415b5aa01165c9133b1eb2d14c4ac181dbe1756669683df0aa911dab2bbd356a2b";
  };

  # Fabric API 0.141.4+1.21.11 (required)
  fabric_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/5zJNhXV2/fabric-api-0.141.4%2B1.21.11.jar";
    sha512 = "c092d48c6453bec3264f80f6a35bb334aba3112b5cd6c0e0b2676ce4d81e702cb1e522337f3a732348e757cc2226da3c601a314ae8766334f16af71a13bcc98d";
  };

  # Fabric Language Kotlin 1.13.11+kotlin.2.3.21 (required)
  fabric_language_kotlin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/2i87JpYj/fabric-language-kotlin-1.13.11%2Bkotlin.2.3.21.jar";
    sha512 = "fa5ed2613f7216999cc0c5ddc71906f082a32b52507d7160acbdcf0eb8de12993ba302e5afde6681d025008ecc66c7533fc0c21deb672ef681b2194fb9be4245";
  };

  # FallingTree 1.21.11-1.21.11.3 (required)
  fallingtree = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Fb4jn8m6/versions/Hnj3s9Ez/FallingTree-1.21.11-1.21.11.3.jar";
    sha512 = "56b8b86846e65f9e070ee08af1baf0b8871ea5eb233a43961d0f937a6147f039eed44794a6b3661b4748e4da037e40aa48b903936960585b626bc9f5e9e308d9";
  };

  # Farmer's Delight 1.21.11-3.4.9 (required)
  farmers_delight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/7vxePowz/versions/ZP4Uof9C/FarmersDelight-1.21.11-3.4.9%2Brefabricated.jar";
    sha512 = "732255187fdb84f71a5e22cb331d068a1a513e51c90e5970f2d31c424973dda3c2c16da49b02df582e23f5af9b8080bef79ef8e627b8ede6ddfcaddccaf245da";
  };

  # FerriteCore 8.2.0-fabric (required)
  ferritecore = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uXXizFIs/versions/Ii0gP3D8/ferritecore-8.2.0-fabric.jar";
    sha512 = "3210926a82eb32efd9bcebabe2f6c053daf5c4337eebc6d5bacba96d283510afbde646e7e195751de795ec70a2ea44fef77cb54bf22c8e57bb832d6217418869";
  };

  # Jade 21.1.6+fabric (required)
  jade = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/swJhAyak/Jade-1.21.11-Fabric-21.1.6.jar";
    sha512 = "6dee10effa6d68c822c59b7704f5506fe674c50d6195da25171641decfa684dc4f14d919656f768fe8fc39003c6193126cb05bb59eed8a1a2bd354dc53875e6d";
  };

  # Just Enough Items 27.4.0.22 (required)
  jei = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/oHe0elMI/jei-1.21.11-fabric-27.4.0.22.jar";
    sha512 = "4de9d355a9a7325590b2064d84e93e217051dc44e2b38f063ad347998af3f0f3a4d1655a020b23d955d78cc66b5443d4f4d5f63a82ac2c0b206b23d9dc1d30ce";
  };

  # Lithium mc1.21.11-0.21.4-fabric (required)
  lithium = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/Ow7wA0kG/lithium-fabric-0.21.4%2Bmc1.21.11.jar";
    sha512 = "f14a5c3d2fad786347ca25083f902139694f618b7c103947f2fd067a7c5ee88a63e1ef8926f7d693ea79ed7d00f57317bae77ef9c2d630bf5ed01ac97a752b94";
  };

  # Lithostitched 1.7.2-fabric-21.11 (required)
  lithostitched = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/XaDC71GB/versions/pLbQKCOo/lithostitched-1.7.2-fabric-21.11.jar";
    sha512 = "77e432cf8932f5a9e6caee5ed4e18d80e0782e5eb9852a0e14c3e2337f5f84ecc579277ac8b7cdbbeaf03ac2fd2b17b68e951a05355c7973df4fd9176774679f";
  };

  # M.R.U 1.0.26+edge+1.21.11-fabric (required)
  mru = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/SNVQ2c0g/versions/XXzIJdq5/mru-1.0.26%2Bedge%2B1.21.11-fabric.jar";
    sha512 = "5da1641bc57d1e04e858fcfa7fe9fe69163e4216f94d5f28430371c98aba1958dc8994243dac816af083033e203df1b51a1a55cea8bf50eadc7dac47136e9ccf";
  };

  # Nature's Compass 1.21.11-2.5.0-fabric (required)
  natures_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fPetb5Kh/versions/7w8oJxSS/NaturesCompass-1.21.11-2.5.0-fabric.jar";
    sha512 = "2cbf53044dcc0564da8098bbbc96e3c0dd49781f020a629642fe5345e1b2b2718ab61ba0bd50f631bae4b13081ee767a2fed29667f7793b44ba2eeed56799cb8";
  };

  # Noisium 2.8.3+mc1.21.11 (required)
  noisium = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/hasdd01q/versions/VyMvRQKq/noisium-fabric-2.8.3%2Bmc1.21.11.jar";
    sha512 = "03d4c116204ee8cb4f95b668576c9e8c099ed939c150ff0cf4ff094ae52b0c5f6214c1292c94f25ea7f614254151d1ff2db68ecaddc9f56486189d29fa3a24eb";
  };

  # Packed Up 1.1.0-fabric-mc1.21.11 (required)
  packed_up = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ZbFzEauY/versions/JAkAbozy/packedup-1.1.0-fabric-mc1.21.11.jar";
    sha512 = "ed1b4961f3a039c95712adf828d22c0aa6ad5d55a956282dfdd26a0e7c60b25691985440bc89c0a69f6339446d219d33afff1f8ba001fc1e7fc8c8d2c392e143";
  };

  # Placeholder API 2.8.2+1.21.10 (required)
  placeholder_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/eXts2L7r/versions/qxjzQ9xY/placeholder-api-2.8.2%2B1.21.10.jar";
    sha512 = "507ab10b7938dcd14d33121b8462649bdbe575cef248e917dfdf7566078ab5d0195ca1add95eae4863de3f652eb56db0a8669a67d5b5344e094d086f9dab5a08";
  };

  # ScalableLux 0.1.6+fabric.c25518a (required)
  scalablelux = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ps1zyz6x/versions/PV9KcrYQ/ScalableLux-0.1.6%2Bfabric.c25518a-all.jar";
    sha512 = "729515c1e75cf8d9cd704f12b3487ddb9664cf9928e7b85b12289c8fbbc7ed82d0211e1851375cbd5b385820b4fedbc3f617038fff5e30b302047b0937042ae7";
  };

  # Sound Physics Remastered fabric-1.21.11-1.5.1 (required)
  sound_physics_remastered = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/qyVF9oeo/versions/pfqxi9qs/sound-physics-remastered-fabric-1.21.11-1.5.1.jar";
    sha512 = "0413e8d654fa5d74dc32ab7c21a82cf8e44aec22c7392648f23a34e2cdb7255af5b34a6016d71bda226c251e5089838f2be9310360723f88e9080fd048efd25f";
  };

  # SuperMartijn642's Config Library 1.1.8-fabric-mc1.21.11 (required)
  supermartijn642_config_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LN9BxssP/versions/CwICbJN9/supermartijn642configlib-1.1.8-fabric-mc1.21.11.jar";
    sha512 = "89330ac0aead9c906a845ca000dafcbacd84185609c306691f64734ef0cffb4b4f4c72d12c7aefad2de8169dcd5d5c25bd79bdfeedf81c0263488290a5f38000";
  };

  # SuperMartijn642's Core Lib 1.1.21-fabric-mc1.21.11 (required)
  supermartijn642_core_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/rOUBggPv/versions/trynou9q/supermartijn642corelib-1.1.21-fabric-mc1.21.11.jar";
    sha512 = "60f918dae4767d60bbff063cf77e7998ff8018c83bc6408d1a8636c4e89bf3e55c5dfd2dabeed2f30d16b25710fbe4028b61445e96f30291274ec6846c68340e";
  };

  # Tectonic 3.0.19 (required)
  tectonic = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lWDHr9jE/versions/7olSYFxL/tectonic-3.0.19-fabric-1.21.11.jar";
    sha512 = "ce0643d45aac7b5e3f3a32fc01928371d97612a9dc6e8df721bf215bf90afa021b8e8d7e19c0d00060c3c98591aec90d2ea51f594fdc0012051f20657fae85ef";
  };

  # Terralith 2.6.1 (required)
  terralith = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/8oi3bsk5/versions/vVdNToqE/Terralith_1.21.11_v2.6.1_Fabric.jar";
    sha512 = "c502e8c18cc6b749fd3d5e8fc6e1d3fc91cdb9763c58c1c7e68c2ea69fb61f27259128171d5f50b2aaa0ea6a7753fcc293f14127110f5f4d2e2141758ffd469e";
  };

  # Towns and Towers 1.13.9 (required)
  towns_and_towers = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/DjLobEOy/versions/qb0cwwDT/t_and_t-fabric-neoforge-1.13.9.jar";
    sha512 = "e0f743b746e78b271bca04c8684408eeb8e4a8570dccc4eebabc62a774c8404569963090f04056bb0f25bb39116a1b8ee47840dfd75a1c415ac5dfb41678b6c9";
  };

  # Waystones 21.11.9+fabric-1.21.11 (required)
  waystones = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LOpKHB2A/versions/MydMW2TT/waystones-fabric-1.21.11-21.11.9.jar";
    sha512 = "047049d8c97c2acdf33c9abaaa6fa2da0ac4c57f81a4961a25c3d58addc6adfcdcc793a7bf6ca1b379312ace69f48b0d7c383b5f1d4309919178632b46ded978";
  };

  # Voxy World Gen V2 2.2.4 (required)
  voxy_world_gen = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/xT0lnNE9/versions/68QZfMFI/Voxy%20World%20Gen%20V2-1.21.11-2.2.4.jar";
    sha512 = "40a137479c0528f0fea159379021520bdd26e3187092ed346fccd12aad4d7d0539ee13a7cd0240b2db435a4548a67b6a20f80e9b61f5ab68fc579759d2b94db7";
  };

  # Voxy Server Side 0.2.2 (required)
  voxy_server_side = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/84zcagOb/versions/27xuJ82D/voxy-server-side-fabric.jar";
    sha512 = "6afe7e71fdb2e80eab126a0e998f98ea51f9428b8ba0a1e3ce20caa12157d4c6ccb80f6ed5dbc1e372d43054980e3de116765e57bfc2e660c3e5e398074915a7";
  };

  # Xaero's Minimap fabric-1.21.11-25.3.12 (required)
  xaeros_minimap = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1bokaNcj/versions/q5DQinHS/xaerominimap-fabric-1.21.11-25.3.12.jar";
    sha512 = "5072fe7d02471956d227b834ee1fa5b1a752f7546cf880c99e32790f09b3b13143c5c16c99b3ba39e0de8a8e6d46f37f1bb3a88ff0fa41207ccce5deae45681b";
  };

  # Xaero's World Map fabric-1.21.11-1.40.16 (required)
  xaeros_world_map = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/NcUtCpym/versions/vOQ76ooY/xaeroworldmap-fabric-1.21.11-1.40.16.jar";
    sha512 = "70bb88a05f8b36dfa39ef971d3e757beeb6845e674d2cfa337fa0a48f003bdc7fe4f6af1f0fa0dfd0ab17593df4f4348528d7952781abeb6a46cff00d693520b";
  };

  # YetAnotherConfigLib 3.8.2+1.21.11-fabric (required)
  yet_another_config_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/pHWDw3Vc/yet_another_config_lib_v3-3.8.2%2B1.21.11-fabric.jar";
    sha512 = "392db7d471030cca27483ecf58c626a14cd73d71a18afe6d4173c6b030948b8a925b36e708d4cc2c897dfa3f20a7f23b999fc18aa6d36c156da29037601153ac";
  };
}
