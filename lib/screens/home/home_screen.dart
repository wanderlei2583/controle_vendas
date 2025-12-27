import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/dashboard_provider.dart';
import '../categorias/categoria_list_screen.dart';
import '../produtos/produto_list_screen.dart';
import '../vendas/venda_list_screen.dart';
import '../estoque/estoque_screen.dart';
import '../configuracoes/configuracoes_screen.dart';
import 'widgets/metric_card.dart';
import 'widgets/sales_chart.dart';

/// Tela inicial do aplicativo
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    VendaListScreen(),
    EstoqueScreen(),
    _RelatoriosTab(),
  ];

  void changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Vendas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Estoque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.store,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text(
                    'Sistema de Controle de Vendas',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text(AppStrings.categorias),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriaListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text(AppStrings.produtos),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProdutoListScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text(AppStrings.configuracoes),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracoesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text(AppStrings.sobre),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: AppStrings.appName,
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.store, size: 48),
                  children: [
                    const Text('Sistema de controle de vendas para pequenos negócios.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs (serão implementados nas próximas fases)

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DashboardProvider>().carregarDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().carregarDashboard();
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.carregarDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Estatísticas do dia
                Text(
                  'Hoje',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Vendas do Dia',
                        value: CurrencyFormatter.format(provider.vendasDoDia),
                        icon: Icons.shopping_bag,
                        color: Colors.blue,
                        subtitle: '${provider.vendasDoDiaCount} vendas',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Lucro do Dia',
                        value: CurrencyFormatter.format(provider.lucroDoDia),
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Estatísticas gerais
                Text(
                  'Geral',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Total Vendas',
                        value: CurrencyFormatter.format(provider.totalVendas),
                        icon: Icons.attach_money,
                        color: AppColors.primary,
                        subtitle: '${provider.quantidadeVendas} vendas',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Lucro Total',
                        value: CurrencyFormatter.format(provider.totalLucro),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                        subtitle: '${provider.margemLucro.toStringAsFixed(1)}% margem',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Ticket Médio',
                        value: CurrencyFormatter.format(provider.ticketMedio),
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Estoque',
                        value: '${provider.estoquesZerados}',
                        icon: Icons.warning,
                        color: Colors.red,
                        subtitle: '${provider.estoquesBaixos} baixos',
                        onTap: () {
                          // Navegar para estoque
                          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                          homeState?.changeTab(2);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Gráfico de vendas
                Text(
                  'Vendas dos Últimos 7 Dias',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Container(
                    height: 250,
                    padding: const EdgeInsets.all(8),
                    child: SalesChart(
                      dados: provider.vendasPorDia,
                      mostrarLucro: false,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Produtos mais vendidos
                if (provider.produtosMaisVendidos.isNotEmpty) ...[
                  Text(
                    'Produtos Mais Vendidos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.produtosMaisVendidos.take(5).map((produto) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${produto.quantidadeVendida}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(produto.nomeProduto),
                        subtitle: Text(produto.nomeVariacao),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(produto.valorTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(produto.lucro),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RelatoriosTab extends StatelessWidget {
  const _RelatoriosTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informação
          Card(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gere relatórios em PDF das suas vendas e compartilhe',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            'Relatórios Disponíveis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Cards de ações
          _buildReportCard(
            context,
            icon: Icons.receipt_long,
            title: 'Relatório de Vendas',
            subtitle: 'Gere PDF com vendas por período',
            color: Colors.blue,
            onTap: () {
              // TODO: Implementar tela de seleção de período
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selecione uma venda na aba "Vendas" e clique no ícone PDF'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildReportCard(
            context,
            icon: Icons.inventory_2,
            title: 'Relatório de Estoque',
            subtitle: 'Visualize produtos e quantidades',
            color: Colors.orange,
            onTap: () {
              // Navegar para aba de estoque
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.changeTab(2);
            },
          ),
          const SizedBox(height: 12),

          _buildReportCard(
            context,
            icon: Icons.trending_up,
            title: 'Dashboard Financeiro',
            subtitle: 'Veja gráficos e estatísticas',
            color: Colors.green,
            onTap: () {
              // Navegar para aba de dashboard
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.changeTab(0);
            },
          ),
          const SizedBox(height: 12),

          _buildReportCard(
            context,
            icon: Icons.backup,
            title: 'Backup de Dados',
            subtitle: 'Faça backup do banco de dados',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracoesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
