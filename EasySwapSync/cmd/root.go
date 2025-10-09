package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
// rootCmd 代表在不调用任何子命令时执行的基础命令
// 初始化一个 cobra.Command 结构体指针，用于定义命令行程序的根命令
var rootCmd = &cobra.Command{
	// Use 字段定义了命令的使用名称，用户在命令行中输入此名称来执行该命令
	Use: "sync",
	// Short 字段提供了命令的简短描述，通常在命令帮助的简要列表中显示
	Short: "root server.",
	// Long 字段提供了命令的详细描述，通常在命令的完整帮助信息中显示
	Long: `root server.`,
	// Uncomment the following line if your bare application has an action associated with it:
	// 若基础应用需要关联一个操作，可取消下面这行的注释
	// Run 字段是一个函数，当命令被执行时会调用该函数
	// Run: func(cmd *cobra.Command, args []string) { },
}

// Execute 函数用于将所有子命令添加到根命令，并正确设置标志。
// 该函数由 main.main() 调用，且仅需对 rootCmd 调用一次。
// 其主要作用是执行根命令，并在执行出错时输出错误信息并退出程序，执行成功后打印配置文件路径。
func Execute() {
	// 调用 rootCmd 的 Execute 方法执行根命令
	// 若执行过程中出现错误，则将错误信息打印到控制台，并以状态码 1 退出程序
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// 根命令执行成功后，打印当前使用的配置文件路径
	fmt.Println("cfgFile=", cfgFile)
}

// init 函数是 Go 语言的初始化函数，会在包被加载时自动执行。
// 此函数的主要作用是进行一些初始化配置，包括设置配置文件初始化函数和定义持久化标志。
func init() {
	// 设置 initConfig 函数在调用 rootCmd 的 Execute() 方法时运行，
	// 确保在执行根命令前完成配置文件的初始化工作。
	cobra.OnInitialize(initConfig)

	// 获取根命令 rootCmd 的持久化标志集合，持久化标志可被所有子命令继承。
	flags := rootCmd.PersistentFlags()

	// 定义一个字符串类型的持久化标志 "--config"，其短标志为 "-c"。
	// 将该标志的值绑定到全局变量 cfgFile 上，默认值为 "./config/config_import.toml"。
	// 该标志用于指定配置文件的路径，帮助信息提示默认配置文件位于用户主目录下的 ".config_import.toml"。
	flags.StringVarP(&cfgFile, "config", "c", "./config/config_import.toml", "config file (default is $HOME/.config_import.toml)")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// 从flag中获取配置文件
		viper.SetConfigFile(cfgFile)
	} else {
		// 主目录 /Users/$HOME$
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// 从主目录下搜索后缀名为 ".toml" 文件 (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigName("config_import")
	}
	viper.AutomaticEnv()                      // 读取匹配的环境变量，自动将环境变量映射到配置中
	viper.SetConfigType("toml")               // 设置配置文件的类型为 TOML
	viper.SetEnvPrefix("EasySwap")            // 设置环境变量的前缀为 "EasySwap"，即只有以该前缀开头的环境变量才会被处理
	replacer := strings.NewReplacer(".", "_") // 创建一个字符串替换器，将 "." 替换为 "_"
	viper.SetEnvKeyReplacer(replacer)         // 设置环境变量键的替换器，将配置键中的 "." 替换为 "_"，以匹配环境变量命名规范
	// 读取找到的配置文件
	if err := viper.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", viper.ConfigFileUsed())
	} else {
		panic(err)
	}

}
