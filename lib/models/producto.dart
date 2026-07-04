class Producto {
  final int sku;
  final String categoria;
  final String nombre;
  final int precio;

  Producto({
    required this.sku,
    required this.categoria,
    required this.nombre,
    required this.precio,
  });

  // Mapeo desde el JSON que entregará la API
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      sku: json['sku'] as int,
      categoria: json['categoria'] as String,
      nombre: json['nombre_producto'] as String,
      precio: json['precio'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'categoria': categoria,
      'nombre_producto': nombre,
      'precio': precio,
    };
  }
}