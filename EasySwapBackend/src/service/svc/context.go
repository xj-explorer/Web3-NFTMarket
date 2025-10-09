package svc

import (
	"context"

	"github.com/ProjectsTask/EasySwapBase/chain/nftchainservice"
	"github.com/ProjectsTask/EasySwapBase/logger/xzap"
	"github.com/ProjectsTask/EasySwapBase/stores/gdb"
	"github.com/ProjectsTask/EasySwapBase/stores/xkv"
	"github.com/pkg/errors"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/core/stores/kv"
	"github.com/zeromicro/go-zero/core/stores/redis"
	"gorm.io/gorm"

	"github.com/ProjectsTask/EasySwapBackend/src/config"
	"github.com/ProjectsTask/EasySwapBackend/src/dao"
)

// ServerCtx 定义服务上下文结构体，包含服务运行所需的各种配置和资源。
type ServerCtx struct {
	// C 存储服务的配置信息。
	C *config.Config
	// DB 存储 GORM 数据库实例。
	DB *gorm.DB
	//ImageMgr image.ImageManager
	// Dao 存储数据访问对象实例。
	Dao *dao.Dao
	// KvStore 存储键值对存储实例。
	KvStore *xkv.Store
	// RankKey 存储排序相关的键。
	RankKey string
	// NodeSrvs 存储不同链 ID 对应的 NFT 链服务实例。
	NodeSrvs map[int64]*nftchainservice.Service
}

func NewServiceContext(c *config.Config) (*ServerCtx, error) {
	var err error
	//imageMgr, err = image.NewManager(c.ImageCfg)
	//if err != nil {
	//	return nil, errors.Wrap(err, "failed on create image manager")
	//}

	// Log
	// 初始化日志配置，调用 xzap.SetUp 方法设置日志。
	_, err = xzap.SetUp(c.Log)
	// 若日志初始化过程中出现错误，则返回错误信息，终止服务上下文的创建。
	if err != nil {
		return nil, err
	}

	var kvConf kv.KvConf
	for _, con := range c.Kv.Redis {
		kvConf = append(kvConf, cache.NodeConf{
			RedisConf: redis.RedisConf{
				Host: con.Host,
				Type: con.Type,
				Pass: con.Pass,
			},
			Weight: 1,
		})
	}

	// redis
	store := xkv.NewStore(kvConf)
	// db
	db, err := gdb.NewDB(&c.DB)
	if err != nil {
		return nil, err
	}

	nodeSrvs := make(map[int64]*nftchainservice.Service)
	for _, supported := range c.ChainSupported {
		nodeSrvs[int64(supported.ChainID)], err = nftchainservice.New(context.Background(), supported.Endpoint, supported.Name, supported.ChainID,
			c.MetadataParse.NameTags, c.MetadataParse.ImageTags, c.MetadataParse.AttributesTags,
			c.MetadataParse.TraitNameTags, c.MetadataParse.TraitValueTags)

		if err != nil {
			return nil, errors.Wrap(err, "failed on start onchain sync service")
		}
	}

	dao := dao.New(context.Background(), db, store)
	serverCtx := NewServerCtx(
		WithDB(db),
		WithKv(store),
		//WithImageMgr(imageMgr),
		WithDao(dao),
	)
	serverCtx.C = c

	serverCtx.NodeSrvs = nodeSrvs

	return serverCtx, nil
}
