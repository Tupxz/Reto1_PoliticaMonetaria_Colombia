#!/bin/bash

# Script para compilar automáticamente reto.tex a PDF
# Uso: bash compilar.sh (desde la carpeta docs/reto/)

echo "🔄 Compilando reto.tex a PDF..."
echo ""

# Verificar que estamos en la carpeta correcta
if [ ! -f "reto.tex" ]; then
    echo "❌ Error: No se encontró reto.tex"
    echo "   Por favor, ejecuta este script desde la carpeta docs/reto/"
    exit 1
fi

# Compilar dos veces (para referencias cruzadas)
echo "📄 Primera pasada..."
pdflatex -interaction=nonstopmode reto.tex > /dev/null 2>&1

echo "📄 Segunda pasada (referencias cruzadas)..."
pdflatex -interaction=nonstopmode reto.tex > /dev/null 2>&1

# Limpiar archivos auxiliares
rm -f reto.aux reto.log reto.out reto.toc 2>/dev/null

# Verificar resultado
if [ -f "reto.pdf" ]; then
    echo ""
    echo "✅ ¡Éxito! Documento compilado: reto.pdf"
    echo "   Tamaño: $(du -h reto.pdf | cut -f1)"
    echo ""
    echo "💡 Para abrir el PDF:"
    echo "   open reto.pdf  (en macOS)"
    echo "   xdg-open reto.pdf  (en Linux)"
else
    echo ""
    echo "❌ Error en la compilación"
    exit 1
fi
