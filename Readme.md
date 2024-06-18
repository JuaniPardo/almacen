# Practica integradora SP, Funciones y Triggers

Crear una base de datos "almacen" que resuelva la siguiente necesidad:

## Necesidad estructural:

- ✅ A- Necesitamos que se almacenen los datos relevantes de un producto:
código único, nombre del producto, fecha de vencimiento, precio y cantidad en stock

- ✅ B- Cada producto pertenece unicamente a una categoria de las cuales necesitamos saber:
nombre de la categoria, descripcion o detalle.

- ✅ C- Necesitamos almacenar los datos de los empleados:
Nombre y apellido, fecha de nacimiento, email, telefono, dni, puesto y direccion.

## Necesidad funcional:

- A- Se necesita tener un control completo del manejo de los productos al inventario. 
  - ✅ A.1 Para lo cual se pide que cada vez que se ingrese un producto nuevo quede registrada la fecha y hora de ingreso, el usuario que realizó la acción.

  - ✅ A.2 Se pide que cada cambio de precios quede registrado con los datos del producto y el empleado que realizó el cambio.

  - ✅ A.3 Se pide que cuando se elimine un producto no desaparezca de los registros.

- ✅ B- El proceso de alta de un empleado se realizará mediante un formulario el cual enviará a la DB los siguientes datos:
-dni, primer nombre, segundo nombre, apellido, mail, telefono, fecha_nacimiento, puesto, calle donde vive, numero de calle, piso, departamento y codigo postal
Se pide que la DB responda con un 1 si los datos se almacenaron correctamente o con un 0 si hubo algun error.

- ✅ C- Existe un formulario en el cual se puede modificar el domicilio de un empleado.
El formulario envia a la base de datos los siguientes datos:
  - dni del empleado
  - calle donde vive
  - numero de calle
  - piso
  - departamento
  - codigo postal. 

  La base de datos devuelve el nombre y apellido del empleado y la direccion nueva como validacion de que se registro el cambio.