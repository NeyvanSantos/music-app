import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();

  final genres = {
    'FUNK': [
      'Reliquia do 2T DJ Gu MC Tuto',
      'Eu Te Seguro Panda',
      'Famoso Ímã MC Lele JP',
      'Amo Minha Favela MC Meno K',
      'Gauchinha MC Ryan SP',
      'Posso Até Não Te Dar Flores MC Ryan SP',
      'Carnívoro MC Lele JP',
      'Jetski Melody',
      'Bola Uma Vela Trava Chip',
      'Set do Japa NK 2.0 MC Ryan SP'
    ],
    'PAGODE': [
      'Bebe E Vem Me Procurar Turma Do Pagode',
      'Grau de Maluca Menos E Mais pagode',
      'Pedindo a Conta Turma do Pagode',
      'Fuso Horário Turma do Pagode',
      'Jejum de Amor Menos E Mais',
      'Amanhã Loucura do Seu Coração Sorriso Maroto',
      'Me Olha Nos Olhos Sorriso Maroto',
      'Quando Erro Contra Erro Grupo Menos E Mais',
      'Amém para Nossa Amizade Vitinho',
      'É Tarde Demais Estou Mal Sorriso Maroto'
    ],
    'SERTANEJO': [
      'Saudade Do Carai Mari Fernandez',
      'Bebe Beija E Trai Mayke Rodrigo',
      'Calcinha de Renda Gusttavo Lima',
      'Grau de Maluca Guilherme Benuto',
      'Errado o Triplo Oh Perigo Diego Victor Hugo',
      'Manda um Oi Guilherme Benuto',
      'Olho Marrom Luan Santana',
      'Vida de Cão Ponto Final Murilo Huff',
      'Caminhonete Inteira Diego Arnaldo',
      'Primeiro Passo Você de Volta Hugo Guilherme'
    ],
    'POP': [
      'SWIM BTS',
      'Loira Gelada Luísa Sonza',
      'Jetski Pedro Sampaio Pop',
      'Numa Ilha Marina Sena',
      'Quando Você Se Foi Chorei DJ Topo',
      'E agora Luísa Sonza Xamã',
      'Impossível Raphaela Santos',
      'De Todas As Coisas TIAGO IORC',
      'G LATINA Pedro Sampaio',
      'French Kiss Luísa Sonza'
    ]
  };

  print('Começando a buscar dados...');
  String output =
      'final genreTopSongsProvider = FutureProvider<Map<String, List<SongModel>>>((ref) async {\n  return {\n';

  for (final entry in genres.entries) {
    output += "    '${entry.key}': [\n";
    for (final q in entry.value) {
      try {
        final searchList = await yt.search.search(q);
        if (searchList.isNotEmpty) {
          final video = searchList.first;
          final String title = video.title.replaceAll("'", "\\'");
          final String author = video.author.replaceAll("'", "\\'");
          output +=
              "      SongModel(id: '${video.id.value}', title: '$title', artist: '$author', thumbnailUrl: '${video.thumbnails.mediumResUrl}', youtubeId: '${video.id.value}', source: SongSource.youtube),\n";
        } else {
          output += '      // Não encontrou: $q\n';
        }
      } catch (e) {
        output += '      // Erro em: $q\n';
      }
    }
    output += '    ],\n';
  }

  output += '  };\n});';

  File('output_provider.txt').writeAsStringSync(output);
  yt.close();
  print('Finalizado!');
}
