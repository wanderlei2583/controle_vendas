import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

/// Serviço para backup e restauração do banco de dados
class BackupService {
  final DatabaseHelper _databaseHelper;

  BackupService(this._databaseHelper);

  /// Cria um backup do banco de dados
  Future<File> criarBackup() async {
    try {
      // Obtém o caminho do banco de dados atual
      final dbPath = await _databaseHelper.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Banco de dados não encontrado');
      }

      // Cria o diretório de backup
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Nome do arquivo de backup com timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'controle_vendas_backup_$timestamp.db';
      final backupPath = path.join(backupDir.path, backupFileName);

      // Copia o arquivo do banco de dados
      final backupFile = await dbFile.copy(backupPath);

      return backupFile;
    } catch (e) {
      throw Exception('Erro ao criar backup: $e');
    }
  }

  /// Compartilha o backup (para enviar por WhatsApp, email, etc.)
  Future<void> compartilharBackup() async {
    try {
      final backupFile = await criarBackup();

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Backup - Controle de Vendas',
        text: 'Backup do banco de dados criado em ${DateTime.now()}',
      );
    } catch (e) {
      throw Exception('Erro ao compartilhar backup: $e');
    }
  }

  /// Restaura o banco de dados a partir de um arquivo de backup
  Future<void> restaurarBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        throw Exception('Arquivo de backup não encontrado');
      }

      // Valida se o arquivo é um banco de dados SQLite válido
      final isValid = await _validarBackup(backupFile);
      if (!isValid) {
        throw Exception('Arquivo de backup inválido ou corrompido');
      }

      // Fecha a conexão com o banco atual
      await _databaseHelper.close();

      // Obtém o caminho do banco de dados
      final dbPath = await _databaseHelper.getDatabasePath();

      // Substitui o banco atual pelo backup
      await backupFile.copy(dbPath);

      // Reabre o banco de dados
      await _databaseHelper.database;
    } catch (e) {
      throw Exception('Erro ao restaurar backup: $e');
    }
  }

  /// Permite ao usuário selecionar um arquivo de backup para restaurar
  Future<bool> selecionarERestaurarBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Selecione o arquivo de backup',
      );

      if (result == null || result.files.isEmpty) {
        return false; // Usuário cancelou
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception('Caminho do arquivo inválido');
      }

      await restaurarBackup(filePath);
      return true;
    } catch (e) {
      throw Exception('Erro ao selecionar/restaurar backup: $e');
    }
  }

  /// Lista todos os backups existentes
  Future<List<File>> listarBackups() async {
    try {
      final backupDir = await _getBackupDirectory();

      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList();

      // Ordena por data de modificação (mais recente primeiro)
      files.sort((a, b) {
        final aModified = a.statSync().modified;
        final bModified = b.statSync().modified;
        return bModified.compareTo(aModified);
      });

      return files;
    } catch (e) {
      throw Exception('Erro ao listar backups: $e');
    }
  }

  /// Exclui um arquivo de backup
  Future<void> excluirBackup(File backupFile) async {
    try {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      throw Exception('Erro ao excluir backup: $e');
    }
  }

  /// Exclui todos os backups antigos (mantém apenas os N mais recentes)
  Future<void> limparBackupsAntigos({int manterUltimos = 5}) async {
    try {
      final backups = await listarBackups();

      if (backups.length > manterUltimos) {
        final backupsParaExcluir = backups.skip(manterUltimos);

        for (final backup in backupsParaExcluir) {
          await excluirBackup(backup);
        }
      }
    } catch (e) {
      throw Exception('Erro ao limpar backups antigos: $e');
    }
  }

  /// Obtém informações sobre um arquivo de backup
  Future<Map<String, dynamic>> obterInfoBackup(File backupFile) async {
    try {
      final stat = await backupFile.stat();
      final sizeInMB = (stat.size / (1024 * 1024)).toStringAsFixed(2);

      return {
        'nome': path.basename(backupFile.path),
        'caminho': backupFile.path,
        'tamanho': '$sizeInMB MB',
        'tamanhoBytes': stat.size,
        'dataCriacao': stat.modified,
      };
    } catch (e) {
      throw Exception('Erro ao obter informações do backup: $e');
    }
  }

  /// Valida se um arquivo é um backup válido do SQLite
  Future<bool> _validarBackup(File backupFile) async {
    try {
      // Verifica se o arquivo tem o cabeçalho do SQLite
      final bytes = await backupFile.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes);

      // O cabeçalho do SQLite deve começar com "SQLite format 3"
      return header.startsWith('SQLite format 3');
    } catch (e) {
      return false;
    }
  }

  /// Obtém o diretório onde os backups são armazenados
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'backups'));
  }

  /// Cria backup automático (pode ser chamado periodicamente)
  Future<void> criarBackupAutomatico() async {
    try {
      await criarBackup();
      await limparBackupsAntigos(manterUltimos: 5);
    } catch (e) {
      // Não lança exceção para não quebrar o fluxo
      print('Erro ao criar backup automático: $e');
    }
  }

  /// Verifica se existe um backup recente (nas últimas 24 horas)
  Future<bool> existeBackupRecente() async {
    try {
      final backups = await listarBackups();

      if (backups.isEmpty) return false;

      final backupMaisRecente = backups.first;
      final info = await obterInfoBackup(backupMaisRecente);
      final dataCriacao = info['dataCriacao'] as DateTime;

      final diferencaHoras = DateTime.now().difference(dataCriacao).inHours;

      return diferencaHoras < 24;
    } catch (e) {
      return false;
    }
  }
}
