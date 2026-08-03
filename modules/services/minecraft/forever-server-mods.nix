# Generated for the Forever NeoForge 1.21.1 pack (neoforge 21.1.235).
# Mirrors the nix-minecraft symlinks.mods/linkFarmFromDrvs pattern.
# Client/server-side split verified against Modrinth client_side/server_side metadata;
# each entry pins the exact version_number the client runs, per mod page.
{pkgs}: {
  # AppleSkin 3.0.9+mc1.21 (neoforge)
  appleskin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/uAKA6Laj/appleskin-neoforge-mc1.21-3.0.9.jar";
    sha512 = "f4ea46273e407334b63e262e2555c9a8204f7b5e60f23f272fbaa83ad9e88800e0ee186aca840710df2dbe0a18b37758695fef2ae1a902c10b3706e3de772937";
  };

  # Architectury 13.0.11+neoforge (neoforge)
  architectury = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/1IiqEQGl/architectury-13.0.11-neoforge.jar";
    sha512 = "d9f7c3bb8162577dfb461ffdf04bd6a3563c7586934a0e2a744c14421beffb8286f0d88d4c758317003f20f99fe8072a39b9d675af061e036970d36db36027f0";
  };

  # Ash API 21.1.1-neoforge (neoforge)
  ash_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Q8xUICr6/versions/3VLPjt5Q/ash_api-neoforge-21.1.1.jar";
    sha512 = "6db5c15b3c0949c1eed65fc1d41ae5eadcbe23e802c6ed5d96d70a3de41c6c10c973a53389ce09c142b1a369904742ba18c88b778b8c18358c27f1ec3e4b3c94";
  };

  # Balm 21.0.64+neoforge-1.21.1 (neoforge)
  balm = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/MBAkmtvl/versions/AMOGoVGH/balm-neoforge-1.21.1-21.0.64.jar";
    sha512 = "e98dfb28aebd14888b4cb219bd88c269ab1991fab4526a3f3b727cdf6e2e919a2b9a8d551c0a37bbc48017089db7260535221555ad7b2eb2fb56d2318a55f4d3";
  };

  # Bookshelf 21.1.81 (neoforge)
  bookshelf = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uy4Cnpcm/versions/1sdJl7J1/bookshelf-neoforge-1.21.1-21.1.81.jar";
    sha512 = "78d4577a8e8fbb241216968475dd73f5b9e5efeb7da802b18a4e6c290e49af6cb4a5676e9855d0d8ff3613f967812e4bd363bbb9196c17c954d19454f84b2214";
  };

  # Carry On 2.2.6 (neoforge)
  carry_on = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/joEfVgkn/versions/PV8oLZ1q/carryon-neoforge-1.21.1-2.2.6.13.jar";
    sha512 = "e097b11d6f14e0957bab6c0276b81542e786cb86b9c31d9f25975f8c9fb04a734188b8790683298bbc5c695dc3de7d6e947616a20ad26d4a728a3beb0bb78667";
  };

  # Chefs Delight 1.0.5 (neoforge)
  chefs_delight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/pvcsfne4/versions/csBO1q5h/chefsdelight-1.0.5-neoforge-1.21.1.jar";
    sha512 = "ea8bb83fd10a9936d52c72b7952ab46674ca3426d741a7e42f301df19e1474b47594ab9ad1b8b424011305f58146522afe4e991d79920a59f7ff066dd9ae620a";
  };

  # Chipped 4.0.2 (neoforge)
  chipped = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/BAscRYKm/versions/eqVowbGc/chipped-neoforge-1.21.1-4.0.2.jar";
    sha512 = "f3083b01267e7c674c4b42f45a317c93ee7723443cba2051fe5bc593638b533b0fe90699e2101661c934dff458eab693cce4e188533bfe977778c249563a2fa5";
  };

  # Chunk Loaders 1.2.9-neoforge-mc1.21 (neoforge)
  chunk_loaders = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/t1VgucWo/versions/lVVhQRyh/chunkloaders-1.2.9-neoforge-mc1.21.jar";
    sha512 = "3cd043e66f5b8fbbf81ae690d4d76fc9f11088e3b0e1c7a3693d3dee5d089ab10e787eab80132857d0c42b67f08f5566ebc0dd37b89e64063c7d9ba1592b7cee";
  };

  # Cloth Config v15 API 15.0.140+neoforge (neoforge)
  cloth_config_v15_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/9s6osm5g/versions/izKINKFg/cloth-config-15.0.140-neoforge.jar";
    sha512 = "aaf9b010955b8cd294e5a92f069985b18729fd5e2cf22d351f1dff9680f15488688803ec41e77e941cbde130ceb535014ca4c868047d80ab69c2d508e216654d";
  };

  # Clumps 19.0.0.1 (neoforge)
  clumps = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Wnxd13zP/versions/jo7lDoK4/Clumps-neoforge-1.21.1-19.0.0.1.jar";
    sha512 = "314d8d8e640d73041f27e0f3f2cad7aad8b4c77dbd7fb31700ef7760362261f77085eed5289555c725d99c3f47a114e7290cd608f39c9f0f12ef74958463bdcc";
  };

  # Collective 1.21.1-8.39-fabric+forge+neo (fabric/forge/neoforge/quilt)
  collective = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/e0M1UDsY/versions/4XRlrKGN/collective-1.21.1-8.39.jar";
    sha512 = "5e8d257650b2ace041df4743172797dfa86faeaa3fa2db13890482f433b189bad037c4f5399b5b5b0e3e65fab0c0887ef65e5c5c24eba6c09da8f95ed3435b02";
  };

  # Comforts 9.0.5+1.21.1 (neoforge)
  comforts = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/SaCpeal4/versions/3kpPjcTc/comforts-neoforge-9.0.5%2B1.21.1.jar";
    sha512 = "e9de2952545e9e773a6e78fc501e8cd231ea19750c30404355b71df9928eb5bd0921a4429aeca9d0fa10e67717f77fcf7a2aae117ac953b8f7de246b0ad685e4";
  };

  # Create 6.0.10+mc1.21.1 (neoforge)
  create = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LNytGWDc/versions/UjX6dr61/create-1.21.1-6.0.10.jar";
    sha512 = "11cc8fc049d2f67f6548c7abfada6b82a3adb5c7ca410a742de04bbca76e03862c518721b88d806f6e6d768a4d68531fdb903a85859b25d1484d550cc7bafd4b";
  };

  # Create Aeronautics 1.3.0+mc1.21.1 (neoforge)
  create_aeronautics = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/oWaK0Q19/versions/w7zlLnea/create-aeronautics-bundled-1.21.1-1.3.0.jar";
    sha512 = "2abba2e166a0ec8d42ab06108b63070d61f985420ecca8739c5b2300561b31486b69b3ad13310b0c459edb9edebeffb55a4cdf4ce493805833d32f5bde9ce778";
  };

  # Create Crafts & Additions neoforge-1.21.1-1.6.0 (neoforge)
  create_crafts_and_additions = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/kU1G12Nn/versions/qPr8V4G2/createaddition-1.6.0.jar";
    sha512 = "e3a31eefb15d37bd1a2ba9012d0c00ec92f7c9e57b7a35c993676ea0cc85ba4f35a055a9f98d57636f24a0562d6da18b4e90713f4f46d47959666a097a6a5cea";
  };

  # Create Deco 2.1.3 (neoforge)
  create_deco = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/sMvUb4Rb/versions/qrcMVoBD/createdeco-2.1.3.jar";
    sha512 = "c536662f9d47ad57a37419165ded14835b23ad6c3e82a920298ecd7ee074244b0b6062ef9cc7ea4501ddd35919a840faccd7fc64e43eb8df31e12076681c3c0d";
  };

  # Create Jetpack 5.2.1 (neoforge)
  create_jetpack = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/UbFnAd4l/versions/sCwiqLqq/create_jetpack-forge-5.2.1.jar";
    sha512 = "dd9856cf9f84d58174bcdb097f405a107d86d0947ab3d67f090994ed3a4939cc9d52bab0f56f988cd290b1e8f68d534c3e9155e33a1d67983d80923f3b67f4f3";
  };

  # Create Slice & Dice 4.3.3 (neoforge)
  create_slice_and_dice = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GmjmRQ0A/versions/N67LJgrN/sliceanddice-4.3.3-neoforge.jar";
    sha512 = "3bdbd282ae5aa11ef6c186b752497541730b50fb400c4962230bcd7734cfe4e8daa2ee565387450dfe0eb6deaa0fa44bf81f99c788bac09b1a60d8f1991db37f";
  };

  # Create Stuff & Additions 2.1.4.a (neoforge)
  create_stuff_and_additions = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/aq9qUUQG/versions/5xWzE6Yk/create-stuff-additions1.21.1_v2.1.4a.jar";
    sha512 = "43e9f5d6fe9faaf1a77b7f979c2f1b7643a90b08c0572d06ef09efcb201d309bb66c32c396ae8383d68c2217224a98dc770290b8291b98edfa37c9bc3fc19a32";
  };

  # Create: Copycats+ 3.0.4+mc.1.21.1-neoforge (neoforge)
  create_copycats = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/UT2M39wf/versions/kecZ0sl7/copycats-3.0.4%2Bmc.1.21.1-neoforge.jar";
    sha512 = "ecc98e659be66a71af0aee66a9f4c7c8838f4f0101402644929079ce7280a572a000e7e417905e1869a51d6e49ebbd601008f54585e07ee4ed01f2c4bc752bfe";
  };

  # Create: Dragons Plus 1.11.4 (neoforge)
  create_dragons_plus = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/dzb1a5WV/versions/PsnDvjPV/CreateDragonsPlus-1.11.4.jar";
    sha512 = "6d2fd22ba66d878ea9a38f50ef0f9738fdc181298b7544059c351fc10ffc33d47d0fe414a14f4888163b228c49201bda15e6dc8af077fa7556ca484e41155267";
  };

  # Create: Enchantment Industry 2.5.0 (neoforge)
  create_enchantment_industry = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/JWGBpFUP/versions/FE6xtrC7/create-enchantment-industry-2.5.0.jar";
    sha512 = "94fe3e30069906aec7c1e62c50e322fedecae5209df8e697f10ac98409b906aea79b4c7781efb0c1733230783ae4f94d4685a0f8cfeeaaae9be44c6ddfabda75";
  };

  # Create: Interiors 0.6.1 (neoforge)
  create_interiors = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/r4Knci2k/versions/gBrfZy6S/interiors-1.21.1-neoforge-0.6.1.jar";
    sha512 = "68b0d915e41fb0ce9d12a8c580d688a604770ded2b21e963058aa6d80cbc5661c481416d051a541395b5c79f461edcb658046e53cfcfb405179a450662ed01b5";
  };

  # Create: New Age 1.2.0+mc1.21.1 (neoforge)
  create_new_age = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/FTeXqI9v/versions/IwtuwMZy/create-new-age-1.2.0%2Bneoforge-mc1.21.1.jar";
    sha512 = "5075c6482b800af7044b594ad694855e7d56f386cb0354967eafe99d77e84b4e26ee7f880d287672d24d84ea8086fd074b7695e46632f32f215b31ce859ada72";
  };

  # Create: Transmission 1.2.1+neoforge-create6-1.21.1 (neoforge)
  create_transmission = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/QFCkBuIh/versions/mLEu54kE/createtransmission-1.2.1%2Bneoforge-create6-1.21.1.jar";
    sha512 = "2d37f1e76a34da5ea52825aaa83848baca2b0327217c034d35188c968df4edad92ff73846cb5d5020aaeacd7350fc00eaa639871dde2ffe6a017fbad3aa87c19";
  };

  # CreativeCore 2.13.41 (neoforge)
  creativecore = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/OsZiaDHq/versions/nLLornod/CreativeCore_NEOFORGE_v2.13.41_mc1.21.1.jar";
    sha512 = "2713dbd456f56f26ef934e5feb4bfb4578a66d0af056eb02670155affceb574d1237203e443e05908d88f3af8de47b52d0216d156028b77b5337f6283b7f4398";
  };

  # Cristel Lib neoforge-1.21.1-3.1.7 (neoforge)
  cristel_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/cl223EMc/versions/Sduz0AWP/cristellib-neoforge-1.21.1-3.1.7.jar";
    sha512 = "6d21ceb6cd91e63a248251ded3812208ed5ea4f36abb11e8c6e16aa119a95b0e714f59ec7689ae1b1248c9831e5e3e63aa681aa7dfa9b220d93741118466cbd6";
  };

  # Distant Horizons 3.2.0-b-1.21.1 (fabric/neoforge)
  distant_horizons = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uCdwusMi/versions/ZpKb4kZp/DistantHorizons-3.2.0-b-1.21.1-fabric-neoforge.jar";
    sha512 = "d4199f92f992fbd2c75a3b0e4e81c8a98bee889013f7347f2149ffa62c86748bde22135e9b2c82a10875db94fa576571c661c5ee16d2f567bd8a93d6f255fd22";
  };

  # EnchantmentDescriptions 21.1.10 (neoforge)
  enchantmentdescriptions = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/UVtY3ZAC/versions/OuJDPGSM/enchdesc-neoforge-1.21.1-21.1.10.jar";
    sha512 = "8932647d23f19ead791a921b0793f61fd7c36601824afef060a55dad9e1ace64f1cb50bd83490d43c9dff3a34661b68b89975f8c4f36b69f36b8e44592d0ad16";
  };

  # Every Compat 1.21-2.11.48 (neoforge)
  every_compat = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/eiktJyw1/versions/K7B7ybsQ/everycomp-1.21-2.11.48-neoforge.jar";
    sha512 = "6e0d1430eda20bbff2b1d42a57ded77e4de558248486f6c031e160cb94b6b217eb2f0259e1a673bfd7957bdcdcb4e97921fbc75245687ff7f4a3b893740d27b2";
  };

  # Explorer's Compass 1.21.1-3.4.0-neoforge (neoforge)
  explorers_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/RV1qfVQ8/versions/hIJ2Ev1Q/ExplorersCompass-1.21.1-3.4.0-neoforge.jar";
    sha512 = "a1b2e385aaacb547763441fc23e9a33a0b1d67bd32094cd605ded3fbdd1c7a0e5fc4520fdfa090c29d2d3384b685e3ead91b32d20030e45632c94145ee3ec668";
  };

  # Farmer's Delight 1.21.1-1.3.2 (neoforge)
  farmers_delight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/R2OftAxM/versions/GbNuOZ4S/FarmersDelight-1.21.1-1.3.2.jar";
    sha512 = "da5a4236427df8010d75992201c8723ac84a8fa71efa55670551d333cac94a90ae8e8c536da63ae07a67f4d00dc2774ae4151030f41d26886e508f4a037c8694";
  };

  # Ferrite Core 7.0.3-neoforge (neoforge)
  ferrite_core = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uXXizFIs/versions/x7kQWVju/ferritecore-7.0.3-neoforge.jar";
    sha512 = "19af89a2075bb10a63884fa853ebf84b02c79dc3242430ecdad056fd764fdcde367a7303276b329df01b0736e2ef264c5d80c7dc92c6aebd244f556a230bb417";
  };

  # Forgified Fabric API 0.116.15+2.3.1+1.21.1 (neoforge)
  forgified_fabric_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Aqlf1Shp/versions/L9bk5uA9/forgified-fabric-api-0.116.15%2B2.3.1%2B1.21.1.jar";
    sha512 = "de6cc76a406371c6cab8600621ea9bf630a796baaa64afa2103a75cddcc8ab52e0a15a5c3dec9b2ed2cf3efcd7d93c622434eb3e8d007361fdd54f2504c09757";
  };

  # Fzzy Config 0.7.6+1.21+neoforge (neoforge)
  fzzy_config = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/hYykXjDp/versions/MAPG6cXE/fzzy_config-0.7.6%2B1.21%2Bneoforge.jar";
    sha512 = "6071890aba7f2273c9fd508914acc7850de9d986423760f9ce416875ffa04eea2ad71a7a6f4d5f90f0625a672f6f54606778d11151b155f3fd98c223c61a4a6d";
  };

  # Handcrafted 4.0.3 (neoforge)
  handcrafted = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/pJmCFF0p/versions/JfqnpP2Z/handcrafted-neoforge-1.21.1-4.0.3.jar";
    sha512 = "4ff5fb2aa9582b886d03f647fe9b8c12a828d29a1787e9c9b463be18192ea798e6a4ac83479623042791bce0bacbf6e3e2c2e9ef086640aeeb6970d3404e7ee4";
  };

  # Immersive Paintings 0.7.8+1.21.1 (neoforge)
  immersive_paintings = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/6txNkua3/versions/DeOfrXC3/immersive_paintings-neoforge-1.21.1-0.7.8.jar";
    sha512 = "f08e759ab6bbdd8b2d00ae3e1cc7044dfe3efa86d34fbbf7553d097ad1be358818d6569902b122cff2654c3a0942eb1a7406cf17ca537386b7d382aa8454b326";
  };

  # Jade 15.10.5+neoforge (neoforge)
  jade = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/yd8FKCmx/Jade-1.21.1-NeoForge-15.10.5.jar";
    sha512 = "678b998677a3d73f98f82dac4093893bfc8a3c2335ec627b4147811c381a040475decdb8db31cc3cbe600abb5a7a6dedcd356eed0ba471af0becdcf49bf5b137";
  };

  # Jade Addons 6.1.0+neoforge (neoforge)
  jade_addons = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/xuDOzCLy/versions/Z9s9lM56/JadeAddons-1.21.1-NeoForge-6.1.0.jar";
    sha512 = "dcf1135718e74c55d4b01116c9955b88a8c8a5180e61dc51d292479aff3d2fff38c8ca0f1b4a6e42e54644f1c8907846a61799491df455b71541aa342d8b8896";
  };

  # JamLib 1.3.6+1.21.1 (neoforge)
  jamlib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/IYY9Siz8/versions/n6UM6TcS/jamlib-neoforge-1.3.6%2B1.21.1.jar";
    sha512 = "c544322a31b5f3fe045cf80eb39e6bd59f91f209a0e510731daa0a6403a273f582769bb26277ef767b4c1ca6438316959d31a6a08e5aa4b1b5a9184a370e5135";
  };

  # Just Enough Items 19.43.0.393 (neoforge)
  just_enough_items = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/Y16jFgP5/jei-1.21.1-neoforge-19.43.0.393.jar";
    sha512 = "04ea7c24a00b980851a34b71899c44731df5b830feafe4172641ae5f42432aabd34ba2ea57fa8f0577823bed0212c4214d409a8ea2060038deed0e8e7e237e81";
  };

  # Kotlin for Forge 5.12.0 (forge/neoforge)
  kotlin_for_forge = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ordsPcFz/versions/uhJhCT7X/kotlinforforge-5.12.0-all.jar";
    sha512 = "b8c3942f4d33179edf3f102f3d870b99dd436f8b8236dbbd31aa51b888162c692cfd88927295f24dc8b4375232f4c6c17360c5d6c4823f93cbcd7cf4bdc8bd14";
  };

  # Lithium mc1.21.1-0.15.4-neoforge (neoforge)
  lithium = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/DDUrRVCA/lithium-neoforge-0.15.4%2Bmc1.21.1.jar";
    sha512 = "2735da2088b88a8bdcd4ad02a2b6fffbfd3925557cefd4fa54b5477dfb9e582ea7f521300c060f57dff1325dd21bff276b7333363ad3371ed6893e3de9eca9cd";
  };

  # Lithostitched 1.7.13-neoforge-21.1 (neoforge)
  lithostitched = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/XaDC71GB/versions/qPASucBM/lithostitched-1.7.13-neoforge-21.1.jar";
    sha512 = "04409013edce65678d02489a7b830ba7d5e18e7c705243c8208f52661da62e7e337a09fe2797c85d7a00bc66cb50949b157b267afd216e7b900ddde9849dff32";
  };

  # Macaw's Bridges 3.1.2 (neoforge)
  macaws_bridges = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GURcjz8O/versions/aQ7rY7ng/mcw-bridges-3.1.2-mc1.21.1neoforge.jar";
    sha512 = "e98e476324229564132288f0a59bfcc897cff4cda7d12fe218563ca48d382d880662375687c69d1b4619144262ae09cbef130f4330474d8eacd37a21e8e9afb4";
  };

  # Macaw's Fences and Walls 1.2.1 (neoforge)
  macaws_fences_and_walls = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GmwLse2I/versions/jVdb0r4W/mcw-mcwfences-1.2.1-mc1.21.1neoforge.jar";
    sha512 = "9bf496a8db8c6074ab32374042ae15e87fe87d897e21de29d459556fa8d7d0e73f2718f28a0236181cfb3c1bc66c776b4d079f0a7084696ad490275ab1b9eb6e";
  };

  # Macaw's Roofs 2.3.2 (neoforge)
  macaws_roofs = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/B8jaH3P1/versions/jiXRXiSt/mcw-roofs-2.3.2-mc1.21.1neoforge.jar";
    sha512 = "c0e82a3d0a3ab2f2fac5fb0bdd7c7c228f084feaa816540d3d9524f341c8b108c3bb1afecadae2e8118e6c93f0e73280c62da1af4349aca87b6aa337e5e22ae4";
  };

  # Macaw's Stairs and Balconies 1.0.2 (neoforge)
  macaws_stairs_and_balconies = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/iP3wH1ha/versions/4t8L0dGP/mcw-mcwstairs-1.0.2-mc1.21.1neoforge.jar";
    sha512 = "51533899b5e64610a642ee9e9d89eb9f193d0877a8cba16d3bfa262789334c864128b01757bff9d3db2718bd3df1fc177f9b2d45b84f06fc0a6ee15474af2fac";
  };

  # Macaw's Windows 2.4.2 (neoforge)
  macaws_windows = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/C7I0BCni/versions/rQUE4LCz/mcw-mcwwindows-2.4.2-mc1.21.1neoforge.jar";
    sha512 = "7628aa390a689a211013e5856cca1c695729b1faa7e20da16fa1f8a3822d5b569631829e91222caa8f1b27c4a7d28ab49110502551551216de2fb471b6f2549f";
  };

  # MidnightLib 1.9.3+1.21.1-neoforge (neoforge)
  midnightlib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/codAaoxh/versions/6Gv5jvTB/midnightlib-neoforge-1.9.3%2B1.21.1.jar";
    sha512 = "5913e7e8ebbffb72323514aa5bedce19056884416d0a33b38af1761ee74cfa600996cde9bd7d709ee2158476faa2e735b2e6ea6107296d471d2c5b7b35d9da6c";
  };

  # ModernFix 5.27.20+mc1.21.1 (neoforge)
  modernfix = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nmDcB62a/versions/VsJnrw8k/modernfix-neoforge-5.27.20%2Bmc1.21.1.jar";
    sha512 = "b1f0d3ac5ada811b8204bc82adc1cab8ff71752da8e97ae381f21be5f778c199ae59108850febc87d1c46757b27ccbb2669f3fc6340c837db450a205ca2d8c9c";
  };

  # Moonlight Lib 1.21.1-3.3.0 (neoforge)
  moonlight_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/twkfQtEc/versions/CitoQHqE/moonlight-neoforge-1.21.1-3.3.0.jar";
    sha512 = "a48a80b9304f9a1d7998fac7b9f06c0fae66984b8073482cd731982f89d59bb66c9f4da9bd37cb33165a2ff15a90141892d4d43973959ed9f19e274538933825";
  };

  # MRU 1.0.31+1.21.1-neoforge (neoforge)
  mru = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/SNVQ2c0g/versions/W0PkvNtT/mru-1.0.31%2B1.21.1-neoforge.jar";
    sha512 = "bf0020381a31b63bb1be64d824ce239552be3bf0a75fe0cc53b5146cec948e794055c3b4cb259f0201f10459d7ff434bfd3bf883541e721cb726e2902829da8e";
  };

  # Nature's Compass 1.21.1-3.4.0-neoforge (neoforge)
  natures_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fPetb5Kh/versions/nFniEtJV/NaturesCompass-1.21.1-3.4.0-neoforge.jar";
    sha512 = "5314b536bcb9a594a9cf2bbd46c82468d17e1559bd6c00da9d91e96c0814f50416799a011705f0d184bd731dac3f03dec009c76fea3d02b3556a6013f9649014";
  };

  # Panda's Falling Trees 0.14.0 (neoforge)
  pandas_falling_trees = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/i2kUe4lq/versions/26ZXBAbi/fallingtrees-neoforge-1.21.1-0.14.0.jar";
    sha512 = "9a7a4efd1f71e73243221d67659ed487212af959decb90fcf5073e5f7fa96dd8c4a7333e9e4fbf053418319f883e1ae3044f3f182c35214c3d6a7de4ef68b8b7";
  };

  # PandaLib 0.6.0 (neoforge)
  pandalib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/mEEGbEIu/versions/RyUlB24m/pandalib-neoforge-1.21.1-0.6.0.jar";
    sha512 = "163eb53f16ec58fbad91aa95fe3870c7f29eb6de43a3b389e19cafed5ae7383f9237e7726584c920f7b3da7feef9bc93c47d254857e31a3c65046ab431b07ce4";
  };

  # Pet Names 1.21.1-3.5-fabric+forge+neo (fabric/forge/neoforge/quilt)
  pet_names = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/tOoh2eQm/versions/mMkhX8oE/petnames-1.21.1-3.5.jar";
    sha512 = "7e538a419c9b7cb558090418be937bc3d7be5908d0a68ed92b3e8b86cbba8e85167ef5ac7bc861ad6b327e9050fad12b22e950f6ff756ba00456f06dc95e5d17";
  };

  # Proxy Compatible Forge 1.3.0 (forge/neoforge)
  # Fixes Velocity's "A packet did not decode successfully (invalid data)" disconnect
  # caused by mod-registered Brigadier command argument types Velocity can't parse
  # (the NeoForge equivalent of CrossStitch, which is Fabric-only).
  proxy_compatible_forge = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/vDyrHl8l/versions/uRu4jaFs/proxy-compatible-forge-1.3.0.jar";
    sha512 = "1587b2d0f6d5397803818f138c6ae17a27e3e5cd03e2b19900672e5a5063c8b548413017e8c444428a643b69b9fd061c9d8efc9020ce9bf866549804da5e24e5";
  };

  # PrickleMC 21.1.11 (neoforge)
  pricklemc = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/aaRl8GiW/versions/EE1FHDyD/prickle-neoforge-1.21.1-21.1.11.jar";
    sha512 = "154d42795ccf1f3e07714775cdb82fd5db17574319286ced13d86b0456b64e4cf5bb89ffbcbfcefce67b73ed0b83e4e2944e493d79d9a385ff9de23006ee7bf5";
  };

  # Rechiseled 1.2.5-neoforge-mc1.21 (neoforge)
  rechiseled = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/B0g2vT6l/versions/S5FnErRw/rechiseled-1.2.5-neoforge-mc1.21.jar";
    sha512 = "d849bc3e775577978bbf96dccee11b0904fa928c556a12e05adf759edab9479bd757f490380475e974eaa137c566ffe8bfb62d5df19f966dfd99b67a2fe0ee9b";
  };

  # Rechiseled: Create 1.1.1-neoforge-mc1.21 (neoforge)
  rechiseled_create = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/E6867niZ/versions/VnOezhJR/rechiseledcreate-1.1.1-neoforge-mc1.21.jar";
    sha512 = "ca77dea4dd3276105176578855b0ffd9f48256bed58701a86171b05db1116a29592871ca7d6d5acc9a023270a45654feb4ab7153026eb751d567e7bf892ca560";
  };

  # Resourceful Lib 3.0.12 (neoforge)
  resourceful_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/G1hIVOrD/versions/x99nCLTm/resourcefullib-neoforge-1.21-3.0.12.jar";
    sha512 = "a9d20e345faa9bcb297bd95ac9524205834804d1bb13518397dd4f7f62b352b08c3339ee7f7870d3669078ceeb33d5c31ea527aecce4b31d62ec1ff7d8b562c8";
  };

  # Right Click Harvest 4.6.1+1.21.1 (neoforge)
  right_click_harvest = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Cnejf5xM/versions/djt0zS53/rightclickharvest-neoforge-4.6.1%2B1.21.1.jar";
    sha512 = "909cc4aba3ed535bb65c4cf285725907f100c0ebbcb619b1c861338b7993a020f0aef953bebeeb74920304c5a80e9cd07654aa5f885a5995824da7cf6784bf42";
  };

  # Sable 2.0.3+mc1.21.1 (neoforge)
  sable = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/T9PomCSv/versions/1L6XJqnY/sable-neoforge-1.21.1-2.0.3.jar";
    sha512 = "c13c4da086001c205361905cd3a6c59a76e3c7d4c082265aaf3baf2fd30c79808f6634bca89aba29db5c096aa7da4066f76454093c306c3ae91c6c0d4d63ae0d";
  };

  # Sinytra Connector 2.0.0-beta.16+1.21.1 (neoforge)
  sinytra_connector = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/u58R1TMW/versions/9Bz9VtV5/connector-2.0.0-beta.16%2B1.21.1-full.jar";
    sha512 = "39094eb8c514db0ffc474bf64a95ebb1a55d50db6a68fcb1dc0fcaea2d1d1fdeb44aa73de9b77a07b04cb7d75741f7c0ac9bb63eae5ded225b2bb0695588c064";
  };

  # Sophisticated Backpacks 1.21.1-3.25.73.2027 (neoforge)
  sophisticated_backpacks = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/TyCTlI4b/versions/8nS2pKnA/sophisticatedbackpacks-1.21.1-3.25.73.2027.jar";
    sha512 = "dacff2f415636d82a154e2e5525485738ae676615c83ebaf08c836872c1f9ea47c9db32a4bb03d71bca1a2e669d8610341d989e0780169aea5f24a82b3a491a3";
  };

  # Sophisticated Core 1.21.1-1.4.80.2194 (neoforge)
  sophisticated_core = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nmoqTijg/versions/Yx6FiECq/sophisticatedcore-1.21.1-1.4.80.2194.jar";
    sha512 = "eff8e9fb5c208a92fae268ea4d9d39f0798d68a31d9c8f9cce7f306c9dddad6c67afe1c58d51347d07d416444553753f8717fc45202ff3cfa4b52a88a88b4642";
  };

  # Sound Physics Remastered neoforge-1.21.1-1.5.1 (neoforge)
  sound_physics_remastered = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/qyVF9oeo/versions/Dd2tmpsk/sound-physics-remastered-neoforge-1.21.1-1.5.1.jar";
    sha512 = "ff7e9f0b968eeb2ba0e833328a122813cad0434cfe2d5c3d527c1c0d564504f13a737fc05f22d3fea562a2f86568d31b95212bf5347dd10da36cd49ad56143a6";
  };

  # SuperMartijn642's Config Library 1.1.8-neoforge-mc1.21 (neoforge)
  supermartijn642s_config_library = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LN9BxssP/versions/qKL9jM75/supermartijn642configlib-1.1.8-neoforge-mc1.21.jar";
    sha512 = "768d8ca178c5e653986f5131b7aeb7fa57ce7d32c16ed399ced01b273565a2b640130c55c7092747efeff40dbb0348876b18b415f59b0d16dd2c7f32f1798ce2";
  };

  # SuperMartijn642's Core Lib 1.1.22-neoforge-mc1.21 (neoforge)
  supermartijn642s_core_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/rOUBggPv/versions/Bw2Pdrfn/supermartijn642corelib-1.1.22-neoforge-mc1.21.jar";
    sha512 = "30b94771ef3879e8bbdecaebb7cd49e5fcd1503efd33eb4f2cdd17eeffa6dd85f9cb4bfc64daafd645ad2946191398d86e75e31e750391a07d3ff6832cd14f6b";
  };

  # Supplementaries 1.21.1-3.8.5 (neoforge)
  supplementaries = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fFEIiSDQ/versions/UPJIp6At/supplementaries-neoforge-1.21.1-3.8.5.jar";
    sha512 = "66663d8acca417c1001c6c49546f89ef3384b6647b9c829a999ed296548314660e9d3f87dafa807429ba790ed2b02bf573068c843140fa23c4d4ce64ad37e130";
  };

  # Terralith 2.6.2 (neoforge)
  terralith = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/8oi3bsk5/versions/IY93YaEe/Terralith_1.21.1_v2.6.2_Neoforge.jar";
    sha512 = "35298f1682567f63dc16658b04cee5498b30819f1c05f9712b4480d7f5eb17059db3b13ab14f81a05fe257149d11ced2cce2030d3727c1747edd8657c53e2a85";
  };

  # Towns and Towers 1.13.9 (fabric/neoforge)
  towns_and_towers = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/DjLobEOy/versions/5PS5OhIh/t_and_t-neoforge-fabric-1.13.9%2B1.21.1.jar";
    sha512 = "a2921584bbb0a79d634b599a1f4327c04eaf44a9846c535450755437fe02a61c5bdaee9070045062e2ae3d0dc35693bc2abf3981b67df9e01e16350a92c59739";
  };

  # Trade Cycling neoforge-1.21.1-1.0.18 (neoforge)
  trade_cycling = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/qpPoAL6m/versions/Dy7xxXr3/trade-cycling-neoforge-1.21.1-1.0.18.jar";
    sha512 = "cd839b97ddcf48ac899c4ecef363f02668abbf18cf2d77823d346f3dacce09f24532636f8de712d8d5ed959cc0b26db23cb98f8837d141731e79c647bd953682";
  };

  # Traveler's Compass 4.0.06 (neoforge)
  travelers_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/WJLLirmC/versions/WNOQCxNt/travelerscompass-neoforge-1.21.1-4.0.06.jar";
    sha512 = "adb34b3964fc2be1c2b04ddbcbde2fdb422447550250e8e4ffc0e9631d10d729edcba564eae553f90d1c3c32d5ac72eb7f3715b5f05ec0429c3ad5085eea0df0";
  };

  # Villager Names 1.21.1-8.5-fabric+forge+neo (fabric/forge/neoforge/quilt)
  villager_names = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gqRXDo8B/versions/2PLlKTES/villagernames-1.21.1-8.5.jar";
    sha512 = "a4bb151ba8a73a608a53d3efcb9ae537e42a80fd332f031556b9260bc4983f831bdb62782d3817aaa0c17d9830b7f498c55a4e1ec23c2a025d3eccf135c8b501";
  };

  # Waystones 21.1.40+neoforge-1.21.1 (neoforge)
  waystones = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LOpKHB2A/versions/u7m5EznS/waystones-neoforge-1.21.1-21.1.40.jar";
    sha512 = "2841bb3651cb5bfb3ac4246c951aba2d9dd660fd5843b3d2b1b17afff8173ca8ec33c51eae50bbc7d6ffd9160f9e5dfd1b1fb4f63bc7d77255f3ad4421fda482";
  };

  # Waystones2Waypoints2 2.1.0 (neoforge)
  waystones2waypoints2 = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/7mLhyqIY/versions/k8wIAiWT/xaeros_waystones_compatibility-NeoForge-1.21.1-2.1.0.jar";
    sha512 = "440da659b1c406ff410841248a28adba60b73f3d91f513ba335b9e5d44b3e48ab63d5ecc86484ff1e3d1a4f7830ad7566fc1efec2a03eba3c958b414b61feea0";
  };

  # Xaero's Minimap neoforge-1.21.1-26.4.2 (neoforge)
  xaeros_minimap = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1bokaNcj/versions/JXvcT1hp/xaerominimap-neoforge-1.21.1-26.4.2.jar";
    sha512 = "7ece42b6665cb3a83d77bca1ae9ab31e9f418a7e0ee73f4be1839b62a8dde7e2727d554b6ed056ca4e7510c1aaa6603e5caaa62355bca9ff202171df73ac49ee";
  };

  # Xaero's World Map neoforge-1.21.1-1.44.2 (neoforge)
  xaeros_world_map = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/NcUtCpym/versions/55gtOc9Y/xaeroworldmap-neoforge-1.21.1-1.44.2.jar";
    sha512 = "4a6b128ca0a07290ad62bab03e98c2ed5c7b37014bb3a3e8e74e7422429ca2cad225c045f9f8f9681662dfda29809dd9cdb2701ba4774a3a57e2fc84eb497fa8";
  };

  # YetAnotherConfigLib 3.8.2+1.21.1-neoforge (neoforge)
  yetanotherconfiglib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/7TVdVtxF/yet_another_config_lib_v3-3.8.2%2B1.21.1-neoforge.jar";
    sha512 = "583de19b927ce8050c2b7d5e60b75accc69e325e5aac85c27994c82a9dec2e4e078343fa1d4c3a10d4bd7e0e524e0b3b246a18cf03db01e363a1e6f865adcf48";
  };

  # YUNG's API 1.21.1-NeoForge-5.1.6 (neoforge)
  yungs_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ua7DFN59/versions/ZB22DE9q/YungsApi-1.21.1-NeoForge-5.1.6.jar";
    sha512 = "5f36d5166a67a156df52699071f20219bc2320b3c4fbcd9dac38631f66136f034e3219ac89ff4bfb6e26e4c68513a94c833797f2e5ed5bf58cfa1531eeed162d";
  };

  # YUNG's Better Dungeons 1.21.1-NeoForge-5.1.4 (neoforge)
  yungs_better_dungeons = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/o1C1Dkj5/versions/D6aZn0Em/YungsBetterDungeons-1.21.1-NeoForge-5.1.4.jar";
    sha512 = "40513bacd13fa9860abcab507b1fc09dc51649af4b615ce466e0ec361557f02d35e6e44bea1cc17cb4120805f862aad01394eb185f46611e7be63dfd97f272df";
  };

  # YUNG's Better Mineshafts 1.21.1-NeoForge-5.1.1 (neoforge)
  yungs_better_mineshafts = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/HjmxVlSr/versions/Go3nbneL/YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar";
    sha512 = "8b01b386f53feeaa55f0c62697578b82e00501e45e428b2a68df6bda34efb6a4b3b4e3582abf13fe767ebcb61aef9368186f53c03999958bef38f31c41a7f8b2";
  };
}
