with Ada.Characters.Latin_1;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;

procedure Main is
   use Ada.Text_IO;

   type Stats is record
      Min, Max : Integer;
      Total, Count : Long_Long_Integer;
   end record;

   type Hash_Mod is mod 2**32;

   function Hash (Key : String) return Ada.Containers.Hash_Type is
      H : Hash_Mod := 0;
   begin
      for I in Key'Range loop
         H := H * 31 + Hash_Mod (Character'Pos (Key (I)));
      end loop;
      return Ada.Containers.Hash_Type (H);
   end Hash;

   package City_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Stats,
      Hash            => Hash,
      Equivalent_Keys => "=");

   M : City_Maps.Map;
   F : File_Type;

   function I (N : Integer) return String is
   begin
      return Ada.Strings.Fixed.Trim (Integer'Image (N), Ada.Strings.Left);
   end I;

   function J (N : Long_Long_Integer) return String is
   begin
      return Ada.Strings.Fixed.Trim (Long_Long_Integer'Image (N), Ada.Strings.Left);
   end J;

   type Key_Array is array (Positive range <>) of String (1 .. 64);
begin
   Open (F, In_File, "../../data/measurements.txt");
   while not End_Of_File (F) loop
      declare
         Line : String (1 .. 256);
         Last : Natural;
         Semi : Natural := 0;
      begin
         Get_Line (F, Line, Last);
         for I in 1 .. Last loop
            if Line (I) = ';' then
               Semi := I;
               exit;
            end if;
         end loop;
         if Semi /= 0 then
            declare
               City : constant String := Line (1 .. Semi - 1);
               Temp : constant String := Line (Semi + 1 .. Last);
               Dstr : String (1 .. Temp'Length);
               D : Natural := 0;
               Value : Long_Long_Integer;
            begin
               for I in Temp'Range loop
                  if Temp (I) /= '.' then
                     D := D + 1;
                     Dstr (D) := Temp (I);
                  end if;
               end loop;
               Value := Long_Long_Integer'Value (Dstr (1 .. D));
               if M.Contains (City) then
                  declare
                     S : Stats := M.Element (City);
                  begin
                     if Value < Long_Long_Integer (S.Min) then
                        S.Min := Integer (Value);
                     end if;
                     if Value > Long_Long_Integer (S.Max) then
                        S.Max := Integer (Value);
                     end if;
                     S.Total := S.Total + Value;
                     S.Count := S.Count + 1;
                     M.Replace (City, S);
                  end;
               else
                  M.Insert
                    (City,
                     (Min => Integer (Value), Max => Integer (Value),
                      Total => Value, Count => 1));
               end if;
            end;
         end if;
      end;
   end loop;
   Close (F);

   declare
      Keys : Key_Array (1 .. Integer (M.Length));
      N : Integer := 0;
   begin
      for C in M.Iterate loop
         declare
            K : constant String := City_Maps.Key (C);
         begin
            N := N + 1;
            Keys (N) := (others => ' ');
            for I in 1 .. K'Length loop
               Keys (N) (I) := K (K'First + I - 1);
            end loop;
         end;
      end loop;

      for I in 2 .. N loop
         declare
            Cur : String (1 .. 64) := Keys (I);
            Jnd : Integer := I - 1;
         begin
            while Jnd >= 1 and then Keys (Jnd) > Cur loop
               Keys (Jnd + 1) := Keys (Jnd);
               Jnd := Jnd - 1;
            end loop;
            Keys (Jnd + 1) := Cur;
         end;
      end loop;

      for L in 1 .. N loop
         declare
            K : constant String := Ada.Strings.Fixed.Trim (Keys (L), Ada.Strings.Right);
            S : constant Stats := M.Element (K);
         begin
            Put (K);
            Put (Ada.Characters.Latin_1.HT);
            Put (I (S.Min));
            Put (Ada.Characters.Latin_1.HT);
            Put (I (S.Max));
            Put (Ada.Characters.Latin_1.HT);
            Put (J (S.Total));
            Put (Ada.Characters.Latin_1.HT);
            Put_Line (J (S.Count));
         end;
      end loop;
   end;
end Main;
