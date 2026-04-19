import yt_dlp
import json
import concurrent.futures

genres = {
    'FUNK': [
        {'title': 'Reliquia do 2T', 'artist': 'DJ Gu, MC Tuto, MC Vine7, MC Joãozinho VT'},
        {'title': 'Eu Te Seguro', 'artist': 'Panda'},
        {'title': 'Famoso Ímã', 'artist': 'MC Lele JP, MC Poze Do Rodo, MC Leozinho ZS'},
        {'title': 'Amo Minha Favela', 'artist': 'MC Meno K, DJ Japa NK'},
        {'title': 'Gauchinha', 'artist': 'MC Ryan SP, MC Brinquedo, MC Meno K'},
        {'title': 'Posso Até Não Te Dar Flores', 'artist': 'MC Ryan SP, MC Meno K, MC Jacaré'},
        {'title': 'Carnívoro', 'artist': 'MC Lele JP, MC Negão Original, MC Jacaré'},
        {'title': 'Jetski', 'artist': 'Melody, Pedro Sampaio, MC Meno K'},
        {'title': 'Bola Uma Vela (Trava Chip)', 'artist': 'MC Meno K, DJ Yuri Pedrada'},
        {'title': 'Set do Japa NK 2.0', 'artist': 'MC Ryan SP, MC IG, Oruam, MC Meno K'}
    ],
    'PAGODE': [
        {'title': 'Bebe E Vem Me Procurar / Quem Ama Sente Saudade', 'artist': 'Turma Do Pagode, Menos É Mais'},
        {'title': 'Grau de Maluca', 'artist': 'Menos É Mais'},
        {'title': 'Pedindo a Conta', 'artist': 'Turma do Pagode, Zeca Pagodinho'},
        {'title': 'Fuso Horário', 'artist': 'Turma do Pagode'},
        {'title': 'Jejum de Amor / Caixa Postal / Vida Vazia', 'artist': 'Grupo Menos É Mais'},
        {'title': 'Amanhã / Loucura do Seu Coração', 'artist': 'Sorriso Maroto, Grupo Menos É Mais'},
        {'title': 'Me Olha Nos Olhos / Futuro Prometido', 'artist': 'Sorriso Maroto, Gloria Groove'},
        {'title': 'Quando Erro Contra Erro', 'artist': 'Grupo Menos é Mais, Simone Mendes'},
        {'title': 'Amém para Nossa Amizade', 'artist': 'Vitinho, Di Propósito'},
        {'title': 'É Tarde Demais / Estou Mal', 'artist': 'Sorriso Maroto, Raça Negra'}
    ],
    'SERTANEJO': [
        {'title': 'Saudade Do Carai', 'artist': 'Mari Fernandez, Grelo, Natanzinho Lima'},
        {'title': 'Bebe, Beija E Trai', 'artist': 'Mayke & Rodrigo, Panda'},
        {'title': 'Calcinha de Renda', 'artist': 'Gusttavo Lima, Panda'},
        {'title': 'Grau de Maluca', 'artist': 'Guilherme & Benuto, Menos É Mais, Matheus Fernandes'},
        {'title': 'Errado o Triplo (Ôh Perigo)', 'artist': 'Diego & Victor Hugo'},
        {'title': 'Manda um Oi', 'artist': 'Guilherme & Benuto, Simone Mendes'},
        {'title': 'Olho Marrom', 'artist': 'Luan Santana'},
        {'title': 'Vida de Cão / Ponto Final', 'artist': 'Murilo Huff, Natanzinho Lima'},
        {'title': 'Caminhonete Inteira', 'artist': 'Diego & Arnaldo, Rionegro & Solimões'},
        {'title': 'Primeiro Passo / Você de Volta', 'artist': 'Hugo & Guilherme, Maria Cecília & Rodolfo'}
    ],
    'POP': [
        {'title': 'SWIM', 'artist': 'BTS'},
        {'title': 'Loira Gelada', 'artist': 'Luísa Sonza'},
        {'title': 'Jetski', 'artist': 'Pedro Sampaio, Melody'},
        {'title': 'Numa Ilha', 'artist': 'Marina Sena'},
        {'title': 'Quando Você Se Foi Chorei (Sorri, Sou Rei)', 'artist': 'DJ Topo, Natiruts'},
        {'title': 'E agora?', 'artist': 'Luísa Sonza, Xamã'},
        {'title': 'Impossível', 'artist': 'Raphaela Santos, LUDMILLA'},
        {'title': 'De Todas As Coisas', 'artist': 'TIAGO IORC, Marina Sena'},
        {'title': 'G-LATINA', 'artist': 'Pedro Sampaio, El Bogueto'},
        {'title': 'French Kiss', 'artist': 'Luísa Sonza, Mc Paiva ZS'}
    ]
}

ydl_opts = {
    'quiet': True,
    'extract_flat': True,
    'force_generic_extractor': False
}

def search_song(genre, item):
    query = f"ytsearch1:{item['title']} {item['artist']}"
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(query, download=False)
        if 'entries' in info and len(info['entries']) > 0:
            entry = info['entries'][0]
            vid_id = entry.get('id', '')
            thumb = f"https://img.youtube.com/vi/{vid_id}/hqdefault.jpg" if vid_id else None
            return genre, item, vid_id, thumb
    return genre, item, None, None

results = {'FUNK': [], 'PAGODE': [], 'SERTANEJO': [], 'POP': []}

tasks = []
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    for g, items in genres.items():
        for i in items:
            tasks.append(executor.submit(search_song, g, i))
            
    for future in concurrent.futures.as_completed(tasks):
        g, item, vid_id, thumb = future.result()
        item['youtubeId'] = vid_id
        item['thumbnailUrl'] = thumb
        results[g].append(item)

output = "final genreTopSongsProvider = FutureProvider<Map<String, List<SongModel>>>((ref) async {\n  return {\n"
for g, items in results.items():
    output += f"    '{g}': [\n"
    for i in items:
        # escapes
        title = i['title'].replace("'", "\\'")
        artist = i['artist'].replace("'", "\\'")
        vid = i['youtubeId']
        thumb = i['thumbnailUrl']
        vid_str = f"'{vid}'" if vid else 'null'
        thumb_str = f"'{thumb}'" if thumb else 'null'
        output += f"      SongModel(id: {vid_str}, title: '{title}', artist: '{artist}', thumbnailUrl: {thumb_str}, youtubeId: {vid_str}, source: SongSource.youtube),\n"
    output += "    ],\n"
output += "  };\n});"

with open("output_python.txt", "w", encoding="utf-8") as f:
    f.write(output)

print("Gerado com sucesso!")
