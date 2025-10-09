package service

import (
	"context"
	"fmt"
	"sync"

	"github.com/ProjectsTask/EasySwapBase/chain"
	"github.com/ProjectsTask/EasySwapBase/chain/chainclient"
	"github.com/ProjectsTask/EasySwapBase/ordermanager"
	"github.com/ProjectsTask/EasySwapBase/stores/xkv"
	"github.com/pkg/errors"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/core/stores/kv"
	"github.com/zeromicro/go-zero/core/stores/redis"
	"gorm.io/gorm"

	"github.com/ProjectsTask/EasySwapSync/service/orderbookindexer"

	"github.com/ProjectsTask/EasySwapSync/model"
	"github.com/ProjectsTask/EasySwapSync/service/collectionfilter"
	"github.com/ProjectsTask/EasySwapSync/service/config"
)

type Service struct {
	ctx              context.Context
	config           *config.Config
	kvStore          *xkv.Store
	db               *gorm.DB
	wg               *sync.WaitGroup
	collectionFilter *collectionfilter.Filter
	orderbookIndexer *orderbookindexer.Service
	orderManager     *ordermanager.OrderManager
}

func New(ctx context.Context, cfg *config.Config) (*Service, error) {
	var kvConf kv.KvConf
	for _, con := range cfg.Kv.Redis {
		kvConf = append(kvConf, cache.NodeConf{
			RedisConf: redis.RedisConf{
				Host: con.Host,
				Type: con.Type,
				Pass: con.Pass,
			},
			Weight: 2,
		})
	}

	kvStore := xkv.NewStore(kvConf)

	var err error
	db := model.NewDB(cfg.DB)
	// 创建集合过滤器实例，用于过滤集合数据
	collectionFilter := collectionfilter.New(ctx, db, cfg.ChainCfg.Name, cfg.ProjectCfg.Name)
	// 创建订单管理器实例，用于管理订单相关操作
	orderManager := ordermanager.New(ctx, db, kvStore, cfg.ChainCfg.Name, cfg.ProjectCfg.Name)
	// 声明订单簿同步器变量，后续根据不同链ID进行初始化
	var orderbookSyncer *orderbookindexer.Service
	// 声明链客户端变量，用于与区块链进行交互
	var chainClient chainclient.ChainClient
	// 打印链客户端连接的URL信息，方便调试
	fmt.Println("chainClient url:" + cfg.AnkrCfg.HttpsUrl + cfg.AnkrCfg.ApiKey)

	chainClient, err = chainclient.New(int(cfg.ChainCfg.ID), cfg.AnkrCfg.HttpsUrl+cfg.AnkrCfg.ApiKey)
	if err != nil {
		return nil, errors.Wrap(err, "failed on create evm client")
	}

	switch cfg.ChainCfg.ID {
	case chain.EthChainID, chain.OptimismChainID, chain.SepoliaChainID:
		orderbookSyncer = orderbookindexer.New(ctx, cfg, db, kvStore, chainClient, cfg.ChainCfg.ID, cfg.ChainCfg.Name, orderManager)
	}
	if err != nil {
		return nil, errors.Wrap(err, "failed on create trade info server")
	}
	manager := Service{
		ctx:              ctx,
		config:           cfg,
		db:               db,
		kvStore:          kvStore,
		collectionFilter: collectionFilter,
		orderbookIndexer: orderbookSyncer,
		orderManager:     orderManager,
		wg:               &sync.WaitGroup{},
	}
	return &manager, nil
}

func (s *Service) Start() error {
	// 不要移动位置
	if err := s.collectionFilter.PreloadCollections(); err != nil {
		return errors.Wrap(err, "failed on preload collection to filter")
	}

	s.orderbookIndexer.Start()
	s.orderManager.Start()
	return nil
}
