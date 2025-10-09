package cmd

import (
	"context"
	"fmt"
	"net/http"
	_ "net/http/pprof"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/ProjectsTask/EasySwapBase/logger/xzap"
	"github.com/spf13/cobra"
	"go.uber.org/zap"

	"github.com/ProjectsTask/EasySwapSync/service"
	"github.com/ProjectsTask/EasySwapSync/service/config"
)

var DaemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "sync easy swap order info.",
	Long:  "sync easy swap order info.",
	Run: func(cmd *cobra.Command, args []string) {
		wg := &sync.WaitGroup{}
		wg.Add(1)
		ctx := context.Background()
		ctx, cancel := context.WithCancel(ctx)

		// rpc退出信号通知chan
		onSyncExit := make(chan error, 1)

		go func() {
			defer wg.Done()

			cfg, err := config.UnmarshalCmdConfig() // 读取和解析配置文件
			if err != nil {
				xzap.WithContext(ctx).Error("Failed to unmarshal config", zap.Error(err))
				onSyncExit <- err
				return
			}

			_, err = xzap.SetUp(*cfg.Log) // 初始化日志模块
			if err != nil {
				xzap.WithContext(ctx).Error("Failed to set up logger", zap.Error(err))
				onSyncExit <- err
				return
			}

			xzap.WithContext(ctx).Info("sync server start", zap.Any("config", cfg))

			s, err := service.New(ctx, cfg) // 初始化服务
			if err != nil {
				xzap.WithContext(ctx).Error("Failed to create sync server", zap.Error(err))
				onSyncExit <- err
				return
			}

			if err := s.Start(); err != nil { // 启动服务
				xzap.WithContext(ctx).Error("Failed to start sync server", zap.Error(err))
				onSyncExit <- err
				return
			}

			if cfg.Monitor.PprofEnable { // 开启pprof，用于性能监控
				http.ListenAndServe(fmt.Sprintf("0.0.0.0:%d", cfg.Monitor.PprofPort), nil)
			}
		}()

		// 信号通知chan
		onSignal := make(chan os.Signal)
		// 优雅退出
		// 使用 signal.Notify 函数监听系统信号，将系统接收到的 SIGINT（通常由 Ctrl+C 触发）和 SIGTERM（通常用于优雅关闭进程）信号发送到 onSignal 通道，
		// 以便程序能够捕获这些信号并执行相应的退出逻辑。
		signal.Notify(onSignal, syscall.SIGINT, syscall.SIGTERM)
		select {
		case sig := <-onSignal:
			switch sig {
			case syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM:
				cancel()
				xzap.WithContext(ctx).Info("Exit by signal", zap.String("signal", sig.String()))
			}
		case err := <-onSyncExit:
			cancel()
			xzap.WithContext(ctx).Error("Exit by error", zap.Error(err))
		}
		wg.Wait()
	},
}

func init() {
	// 将 daemon 子命令添加到主命令 rootCmd 中，使得在执行主命令时可以调用 daemon 命令
	// 该操作允许用户通过主命令入口来启动同步服务守护进程
	rootCmd.AddCommand(DaemonCmd)
}
