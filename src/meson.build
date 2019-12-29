# Programas del proyecto

sources = [
    'gmm/gmm_classify.cpp',
    'gmm/gmm_show.cpp',
    'gmm/gmm_train.cpp',
    'gmm/gmm_verify.cpp',
    'pearson/pearson.cpp',
    'fmatrix/fmatrix_cut.cpp',
    'fmatrix/fmatrix_show.cpp',
    'fmatrix/fmatrix_delta.cpp',
    'fmatrix/fmatrix_delta_static.cpp',
    'fmatrix/fmatrix_delta_dynamic_1.cpp',
    'fmatrix/fmatrix_delta_dynamic_2.cpp',
]

foreach src: sources
    executable(
        src.split('/')[-1].split('.')[0],         # Nombre sin directorio ni extensión
        sources: src,
        include_directories: inc,
        link_args: ['-lm', '-lsndfile'],
        link_with: lib_pav,
        install: true,
    )
endforeach
