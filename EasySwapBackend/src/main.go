package main

import (
	"flag"
	_ "net/http/pprof"

	"github.com/ProjectsTask/EasySwapBackend/src/api/router"
	"github.com/ProjectsTask/EasySwapBackend/src/app"
	"github.com/ProjectsTask/EasySwapBackend/src/config"
	"github.com/ProjectsTask/EasySwapBackend/src/service/svc"
)

const (
	// port       = ":9000"
	// repoRoot          = ""
	defaultConfigPath = "../config/config.toml"
)

func main() {
	conf := flag.String("conf", defaultConfigPath, "conf file path")
	flag.Parse()
	c, err := config.UnmarshalConfig(*conf)
	if err != nil {
		panic(err)
	}

	for _, chain := range c.ChainSupported {
		if chain.ChainID == 0 || chain.Name == "" {
			panic("invalid chain_suffix config")
		}
	}

	// 初始化服务上下文，包含配置、数据库连接、键值对存储等。
	serverCtx, err := svc.NewServiceContext(c)
	if err != nil {
		panic(err)
	}

	// 初始化路由，将服务上下文传递给路由构造函数。
	r := router.NewRouter(serverCtx)
	// 初始化平台实例，传入配置、路由和服务上下文
	app, err := app.NewPlatform(c, r, serverCtx)
	if err != nil {
		panic(err)
	}
	// 启动平台服务
	app.Start()
}
