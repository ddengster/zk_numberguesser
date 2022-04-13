// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;

import "./verifier_common.sol";

contract InitiateGameVerifier {
    using Pairing for *;
    struct IG_VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct IG_Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function IG_verifyingKey() pure internal returns (IG_VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x25a3dd57bbd70b2eafb121b3aeb717585ef5fa8cf64369ac2222d5b6181e0e3b), uint256(0x164c41911d0acda5054026c0e4397f74553980db9c482fbd6ca9764621b7d29f));
        vk.beta = Pairing.G2Point([uint256(0x2b48ca3fcba51bec805cb50486f587f95b42f0289a9aa7863bb99434cb75ee48), uint256(0x172c00db34953365288d6d6a60c4e8ec1ff9253ed16c454516a5ea98f916268d)], [uint256(0x110310ede58984c2ed15e42a9714e80bdf330df3710b9b4e9277db49b2adfd25), uint256(0x1851753d60bab798ccafb7ad46b2c97b91947e819663efa5055478af8cb52409)]);
        vk.gamma = Pairing.G2Point([uint256(0x078ae2e2da39d5df949827d1ee6486cfa8aba5337983aa043e8dcd3b0955ccf1), uint256(0x1fb23ca05029bce620638e0c808fd80ad25a14339b06eb5b03aa0aebb61e29d0)], [uint256(0x13a365f89162e12425bf980d5b8ad8256fcc7327cb577dfdec2ceda5f32ca9d6), uint256(0x14997d7683c09adcad05d56c8b615fa9e936fcf395fa12da678a8a5a5c4d8208)]);
        vk.delta = Pairing.G2Point([uint256(0x07a8ef58c86d01d3e0426bf4573368b155b074c71f7c8b5fc30623dff322814d), uint256(0x19db250af5e1807e79a6a6f41c7c865869d0da29759c31bab906cdb29cbc26cf)], [uint256(0x0632298ccbb9d40f2138610ba1cad89d6cff3be4896de58d4503deafc845cd4c), uint256(0x0505d7d7a655036eee2fc5940a94395659e8286913c2013bced6ac9b1047f929)]);
        vk.gamma_abc = new Pairing.G1Point[](5);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x104e77a59a879876ee3cbbf54cccf8dded4cb88778c822758fb6cd64e4fb77e7), uint256(0x1b4745dcc87bb8e2233d238d5d418f52225abe3fbb64183d63572cc4c4df081e));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0c7023c91533d6f53e65e5b1a154e400f814d12195cdd0498a8703f6a499676d), uint256(0x30464620d9c60b320f09b00da6bc51f40a4996410082cd05422b4e8cd22e783a));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x141f39c3c413c4444d075938c9fa8cf8316876248ec9c34fe0def2fcbc875f9d), uint256(0x0ff352f7499808a422414198ecb88c0a4bd12190785ec0c0edb9c97245f20d2e));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x06ad0941b6c4c05c13e7cc8265f1cad8ee27d8b4abf8b14b7a421c499e682403), uint256(0x119e6d6646df2db34dde9d4c039dc2e8ec7662615593ff90a8fa565e4fb08272));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0111f92d69e95da75e83eb1ef3c829fefb89d52600ae5371aad46f24149fd893), uint256(0x21ce37cd2ed379b07cd40ef77b2433b34d4cdbbc1246c4e8a819c7a77006d721));
    }
    function IG_verify(uint[] memory input, IG_Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        IG_VerifyingKey memory vk = IG_verifyingKey();
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
    function IG_verifyTx(
            IG_Proof memory proof, uint[4] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](4);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (IG_verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
