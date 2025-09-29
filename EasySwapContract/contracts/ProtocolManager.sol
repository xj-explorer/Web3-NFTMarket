// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibPayInfo} from "./libraries/LibPayInfo.sol";

abstract contract ProtocolManager is Initializable,OwnableUpgradeable {
    // 协议分成比例，即收取的手续费比例，使用 uint128 类型存储
    uint128 public protocolShare;

    event LogUpdatedProtocolShare(uint128 indexed newProtocolShare);

    function __ProtocolManager_init(uint128 newProtocolShare) internal onlyInitializing {
        // __Ownable_init(_msgSender());
        // 调用未链接的初始化函数设置协议分成比例
        __ProtocolManager_init_unchained(
            newProtocolShare
        );
    }

    function __ProtocolManager_init_unchained(uint128 newProtocolShare) internal onlyInitializing {
        _setProtocolShare(newProtocolShare);
    }

    function setProtocolShare(uint128 newProtocolShare) external onlyOwner {
        _setProtocolShare(newProtocolShare);
    }

    function _setProtocolShare(uint128 newProtocolShare) internal {
        require(
            newProtocolShare <= LibPayInfo.MAX_PROTOCOL_SHARE,
            "PM: exceed max protocol share"
        );
        protocolShare = newProtocolShare;
        emit LogUpdatedProtocolShare(newProtocolShare);
    }

    uint256[50] private __gap;
}
