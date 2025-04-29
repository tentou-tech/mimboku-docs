# Testing tokens and pools

In order to set up a test environment, we have deployed some testing tokens on the [`Aeneid`](https://chainlist.org/chain/1315) testnet and also deployed testing pools on the two DEXs: [`StoryHunt`](https://aeneid.storyhunt.xyz/my-pools/top) and [`PiperX`](https://piperx.xyz/).

### Token list

|       **Name**       | **Symbol** | **Decimals** |                **Address**                 |
| :------------------: | :--------: | :----------: | :----------------------------------------: |
| Aeneid Bridged USDT  |    USDT    |      18      | 0xD1fa5456186758b84811b929B4D696178fb56eE3 |
| Aeneid Wrapped Ether |    WETH    |      18      | 0x7068F8Cafe1522dd317975BCe80c7A7a4955757D |
|     ERC20 JUTSU      |  JUTSU20   |      18      | 0x5D2Bbf372A716878dc29087C13f7950c4Ce3D973 |
|     WhatTheFreg      |    WTF     |      18      | 0x2bf14fc974049D7FAC0AA252087458470eb27E2E |
|      Pepe Coin       |    PEPE    |      18      | 0x3d05Fd5240e30525B7dCF38683084195B68BE848 |
|       Dogecoin       |    DOGE    |      18      | 0x16dE3577FDc5419D7AeD0c65B6d8B0de5a120842 |
|      Chainlink       |    LINK    |      18      | 0xE9F009727980031Bcb7864fd9ED8876ff8D4bCF8 |
|         Sei          |    SEI     |      18      | 0x21cDE62a066841256a8F89Be36c99824f2590ef2 |
|    Pudgy Penguins    |   PENGU    |      18      | 0xaa3b1e05CE6ddEb1D0ACf527125aE84389961eBF |
|        TokenA        |     TA     |      18      | 0xE99ea1Ed6bFC8c23aCd4C05ad8e63159742BA907 |
|        TokenB        |     TB     |      18      | 0xa39f27cc30FcdF71914FFc802A17E7E2A5399C7d |
|        TokenC        |     TC     |      18      | 0x4327939441970dA9dEe4495479D765e4a5858B0A |
|        TokenD        |     TD     |      18      | 0xb00A7cb16C9BEcA7bb5eEB5dc58C5ED49725c0f5 |

### Pool list

|   **Pair**   | **Fee** | **Type** |                **Address**                 |  **DEX**  |
| :----------: | :-----: | :------: | :----------------------------------------: | :-------: |
|   WIP/USDT   |  3000   |    V3    | 0x8020b70f1f0e55c7b9b26c01b74cbc8a3a77e1d8 | StoryHunt |
|   WIP/WETH   |  3000   |    V3    | 0xbA7CAd6b445B5b3E4DdEc8FE5e0bBA965932af4b | StoryHunt |
|   WIP/USDT   |  3000   |    V3    | 0x7B0AFC0d8A6D88C4Ad3ABA1F3174a3DC8AF33d9e |  PiperX   |
|   WIP/WETH   |  3000   |    V3    | 0xbdB1EfD7058165ae21b7f03eAdE2169c71c0A92d |  PiperX   |
| WIP/JUTSU20  |  3000   |    V3    | 0xd2ae313ef461d211fbb655c99fbebd7fdf9806c2 | StoryHunt |
|   WTF/USDT   |  3000   |    V3    | 0x13C2Ce93e4c56Ad34A606D24c62132f11A03515B | StoryHunt |
| WTF/JUTSU20  |  10000  |    V3    | 0xc7e42e66d09ed9bD054494A167Ac97AD3e701A1f | StoryHunt |
|  PEPE/USDT   |  3000   |    V3    | 0x00f4DeeEc507D81698b434460dF49Aef7C027002 | StoryHunt |
|  DOGE/USDT   |  3000   |    V3    | 0xf712Df8FddF466ACb94d6a1574C03563C74caD6a | StoryHunt |
|  USDT/LINK   |  3000   |    V3    | 0x5FAeE6d74cafD17725296CD33187B9FBee285442 | StoryHunt |
| JUTSU20/USDT |  3000   |    V3    | 0x909328d1b41d8ae0439bb726982e742063a84ab4 | StoryHunt |
|   WTF/LINK   |   500   |    V3    | 0x16adb1Cdcc64Df1ea598F00E96bBBA68811Df436 | StoryHunt |
|   SEI/USDT   |  3000   |    V3    | 0xA14290D45F895Dc70Dcb1CD24B25319822d1c2Ce |  PiperX   |
|  USDT/PENGU  |  3000   |    V3    | 0x16adb1Cdcc64Df1ea598F00E96bBBA68811Df436 |  PiperX   |
|    TB/TA     |  3000   |    V3    | 0xa7a45c47b6bcbe44e487180fcbbda294d32234cc | StoryHunt |
|    TC/TB     |  3000   |    V3    | 0xa124c61ffd26a325fa0c9f1f0964360a7b36edc2 | StoryHunt |
|    TD/TA     |  3000   |    V3    | 0x3ebce1f88f52aad48a9afc34dfdd4aaef6835622 | StoryHunt |
|    TC/TD     |  3000   |    V3    | 0xfeceb1894e28fe4c032abfd236793bcf7c2a5fe8 | StoryHunt |
|    TC/TB     |  3000   |    V3    | 0xe4F00B52a8B11E7A13a1880A2501f377ce035570 |  PiperX   |
|    TC/TD     |  3000   |    V3    | 0x8C6532197EAF75F0Aa9c6b2D0c9C7186C05fAEa1 |  PiperX   |
|    TC/TA     |  3000   |    V3    | 0xa7f8cA66fF5E34b0C102F07046282C23D4bfaC6D |  PiperX   |
|   WIP/USDT   |         |    V2    | 0xbbe72f551df1dbe7136af12b66866afdbae9dad7 |  PiperX   |
|    TB/TA     |         |    V2    | 0xf5705fe9f80678bc6e0421aa2b3d9ee4dfdb982d |  PiperX   |
|    TC/TA     |         |    V2    | 0x211d7d4f0d2192b97a62a85af3fa8491f5ecfbec |  PiperX   |
|    TD/TA     |         |    V2    | 0x89a6a70e87a836db8312a9af837e398f4fdf733e |  PiperX   |
|    TC/TB     |         |    V2    | 0x1af47b21c7387bb45f6f74ec971b32513da65adb |  PiperX   |
