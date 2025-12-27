import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../services/backup/backup_service.dart';
import '../../services/database/database_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/date_formatter.dart';

/// Tela de Configurações
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late BackupService _backupService;
  bool _isLoading = false;
  List<File> _backups = [];

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(DatabaseHelper());
    _carregarBackups();
  }

  Future<void> _carregarBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.listarBackups();
      setState(() => _backups = backups);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar backups: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _criarBackup() async {
    setState(() => _isLoading = true);
    try {
      await _backupService.compartilharBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup criado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _carregarBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restaurarBackup() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: const Text(
          'Atenção! Esta ação substituirá todos os dados atuais pelo backup selecionado. '
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _isLoading = true);
    try {
      final sucesso = await _backupService.selecionarERestaurarBackup();

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restaurado com sucesso! Reinicie o aplicativo.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _limparBackupsAntigos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Backups Antigos'),
        content: const Text(
          'Isso manterá apenas os 5 backups mais recentes. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.limparBackupsAntigos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backups antigos removidos com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _carregarBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar backups: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.configuracoes,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seção de Backup
                _buildSectionTitle('Backup e Restauração'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.backup,
                          color: AppColors.primary,
                        ),
                        title: const Text('Criar Backup'),
                        subtitle: const Text(
                          'Cria uma cópia de segurança do banco de dados',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _criarBackup,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.restore,
                          color: AppColors.warning,
                        ),
                        title: const Text('Restaurar Backup'),
                        subtitle: const Text(
                          'Restaura o banco de dados de um backup',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _restaurarBackup,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.cleaning_services,
                          color: Colors.orange,
                        ),
                        title: const Text('Limpar Backups Antigos'),
                        subtitle: const Text(
                          'Remove backups antigos (mantém os 5 mais recentes)',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _limparBackupsAntigos,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Lista de Backups
                _buildSectionTitle('Backups Disponíveis'),
                const SizedBox(height: 8),
                if (_backups.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nenhum backup encontrado',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._backups.map((backup) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _backupService.obterInfoBackup(backup),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Card(
                            child: ListTile(
                              leading: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final info = snapshot.data!;
                        final dataCriacao = info['dataCriacao'] as DateTime;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.file_present,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              DateFormatter.formatDateTime(dataCriacao),
                            ),
                            subtitle: Text('Tamanho: ${info['tamanho']}'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                              ),
                              onPressed: () async {
                                final confirmado = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Excluir Backup'),
                                    content: const Text(
                                      'Deseja realmente excluir este backup?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmado == true) {
                                  await _backupService
                                      .excluirBackup(backup);
                                  await _carregarBackups();

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Backup excluído com sucesso!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),

                const SizedBox(height: 24),

                // Seção Sobre
                _buildSectionTitle('Sobre'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        title: const Text('Versão do App'),
                        subtitle: const Text('1.0.0'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text('Sobre o Sistema'),
                        subtitle: const Text(
                          'Sistema de controle de vendas para pequenos negócios',
                        ),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: AppStrings.appName,
                            applicationVersion: '1.0.0',
                            applicationIcon:
                                const Icon(Icons.store, size: 48),
                            children: const [
                              Text(
                                'Sistema completo para gerenciar produtos, estoque, vendas e relatórios.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }
}
