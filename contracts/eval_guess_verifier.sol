// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;

import "./verifier_common.sol";

contract EvalGuessVerifier {
    using Pairing for *;
    struct EV_VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct EV_Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function EV_verifyingKey() pure internal returns (EV_VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x25b65ca00afe006102502da06bb4a3a46324d3536307b120eef327062e02f3b3), uint256(0x22bdd7045ec55bbcca1e9fd779b5927e9cad373693e0f8db4d9d3b81b2d8a3d7));
        vk.beta = Pairing.G2Point([uint256(0x23f8f14c5a6f3e3d23e27be7cf8e34e7ecef08acc7b8c1460dba56f71b6b4f40), uint256(0x0849fd20a5e6f7d2435cd0d9fcd9e8fcd2b76853793cd76a3db25930978558ef)], [uint256(0x052b5e9ac69a9a28bd00e766439ffe0ffd1cb9a0c1c3a1fdcdc7d9701237df47), uint256(0x1db29152d192bdfbe5e995988b1fafdef023982faf28522a76fc12a9408a9528)]);
        vk.gamma = Pairing.G2Point([uint256(0x17cd30084634c2a7b5f85aa42958e15a2fe126ff7d129bd9abd5ea74b91ce0dd), uint256(0x25464198aa5181bc3ed8ba41d2c0134195fd5bde6682cdf3b3779fc78b1e9242)], [uint256(0x0f6c31984c8fb223f169745a9234ff3170ca30936c95d643fe6e718024afe0f6), uint256(0x23bb0f59aa1d927bdc842e7719a75046785f057c3d9c41004d630037d6a586f4)]);
        vk.delta = Pairing.G2Point([uint256(0x10cf829878235563f20e82a044b1fa4cd068c00b9f792b6cbbb50ddd877d35a1), uint256(0x1c1dec10b6baee2d8764308a2d2bc4e478010a5b92b3ceae16e874f88c405e4a)], [uint256(0x1c80f6ce1173d5c4a910b551f25a227f47e86be656c12452facdf18b8d5536a1), uint256(0x0a3e7f1460cf222ffbb329b4b7122e87f5da92327cf7bae57a2fd1e74b728de4)]);
        vk.gamma_abc = new Pairing.G1Point[](4);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1ca7f2e22b8de47601baafb0f1abc01fbb86afbe1a2d94e356c05086e8e60e4f), uint256(0x03281980a2d2a2428ce89da1fb21f6b5db9afe0964b6f542c141c0661bb2e817));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x051949c79d83b890672f1c1edcf5b7bba3ce043366ccbcd3aa7a506e0607ce52), uint256(0x106295f50a052e660c0f85774a976a6121ca6fdc8cc616beadef2e68f1fe5118));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x12fdbb7f292fae4440e30dd8a56c6803ddb934a11b70ee9abd0eda4220f1e334), uint256(0x017ab6963944d14b5766dd8fd3bf96a52b8342c177a816ec7a7bcf9c344cbf3c));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2a2864243c95a30007a3b1b53a0e11dd199d8f93eebff7512b611428c4c83205), uint256(0x1a4944da2c5b34cc4b6a24e2fcc0885dbc89f0ab7d7029937a2bca59b16a743a));
    }
    function EV_verify(uint[] memory input, EV_Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        EV_VerifyingKey memory vk = EV_verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function EV_verifyTx(
            EV_Proof memory proof, uint[3] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](3);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (EV_verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
