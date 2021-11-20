! sql_atlnts.f90
! Author: Bishoy Roufael
! Handy functions for adding lost and found items to a sql database using sqlite3
! Meant to be used with the CGI to recieve get and post requests from a front end
! For @JacobsHack 2021!

module sql_atlnts
    use, intrinsic :: iso_c_binding 
    use :: sqlite
implicit none
    character(len=:), allocatable :: errmsg

contains
    subroutine get_user_lafi_json(db, rc, stmt, user_name, json_o)
        type(c_ptr), intent(inout) :: db
        type(c_ptr), intent(inout) :: stmt
        integer, intent(inout) :: rc
        character(len=:), allocatable, intent(inout) :: json_o
        character(len=:), allocatable, intent(inout) :: user_name
        character(len=:), allocatable :: query
        query = "SELECT * FROM lafItems WHERE user_name='"
        query = trim(query) // trim(user_name) // trim("'")
        call json_db(db, rc, stmt, query, json_o)
    end subroutine get_user_lafi_json

    subroutine get_all_lafi_json(db, rc, stmt, json_o)
        type(c_ptr), intent(inout) :: db
        type(c_ptr), intent(inout) :: stmt
        integer, intent(inout) :: rc
        character(len=:), allocatable, intent(inout) :: json_o
        character(len=:), allocatable :: query
        query = "SELECT * FROM lafItems"
        call json_db(db, rc, stmt, query, json_o)
    end subroutine get_all_lafi_json

    subroutine json_db(db, rc, stmt, query, db_json )
        type(c_ptr), intent(inout) :: db
        type(c_ptr), intent(inout) :: stmt
        integer, intent(inout) :: rc
        character(len=:), allocatable :: row_json
        character(len=:), allocatable, intent(inout) :: query
        character(len=:), allocatable, intent(inout) :: db_json
        db_json = '{"result":['

        ! Read values from database.
        rc = sqlite3_prepare(db, query, stmt)

        ! Print rows line by line.
        do while (sqlite3_step(stmt) /= SQLITE_DONE)
            call print_values(stmt, 8, row_json)
            db_json = trim(db_json) // trim(row_json) // trim(',')
        end do

        db_json = trim(adjustl(db_json(0: len(db_json)-1)))
        db_json = trim(db_json) // trim(']}')

        ! Delete the statement.
        rc = sqlite3_finalize(stmt)
    end subroutine json_db
    subroutine create_db(db, rc)
        type(c_ptr), intent(inout) :: db
        integer, intent(inout) :: rc
        ! Open SQLite database.
        rc = sqlite3_open('atlnts-laf.db', db)

        ! Create table.
        rc = sqlite3_exec(db, "CREATE TABLE lafItems (" // &
                            "item_id     INTEGER PRIMARY KEY," // &
                            "user_name VARCHAR(32)," // &
                            "item_name VARCHAR(128)," // &
                            "item_description TEXT," // &
                            "item_location VARCHAR(128)," // &
                            "item_images VARCHAR(256)," // &
                            "lost_date VARCHAR(64)," // &
                            "reward_price DOUBLE)", c_null_ptr, c_null_ptr, errmsg)
                            
        if (rc /= SQLITE_OK) print '("sqlite3_exec(): ", a)', errmsg
    end subroutine create_db
    
    
    subroutine insert_row(db,rc, stmt, user_name,item_name, item_description, item_location, item_images, lost_date, reward_price)
        type(c_ptr), intent(inout) :: db
        type(c_ptr), intent(inout) :: stmt
        integer, intent(inout) :: rc
        character(len=*), intent(in) :: user_name
        character(len=*), intent(in) :: item_name
        character(len=*), intent(in) :: item_description
        character(len=*), intent(in) :: item_location
        character(len=*), intent(in) :: item_images
        character(len=*), intent(in) :: lost_date
        real(8), intent(in) :: reward_price
        ! Create a prepared statement.
        rc = sqlite3_prepare(db, "INSERT INTO lafItems (" // & 
                                    "user_name," // &
                                    "item_name," // &
                                    "item_description," // &
                                    "item_location," // &
                                    "item_images," // &
                                    "lost_date," // &
                                    "reward_price" // &
                                    ") VALUES (" // &
                                    "?,?,?,?,?,?,?)", stmt)

        ! Bind the values to the statement.
        rc = sqlite3_bind_text(stmt, 1, user_name)
        rc = sqlite3_bind_text(stmt, 2, item_name)
        rc = sqlite3_bind_text(stmt, 3, item_description)
        rc = sqlite3_bind_text(stmt, 4, item_location)
        rc = sqlite3_bind_text(stmt, 5, item_images)
        rc = sqlite3_bind_text(stmt, 6, lost_date)
        rc = sqlite3_bind_double(stmt, 7, reward_price)

        ! Run the statement.
        rc = sqlite3_step(stmt)
        if (rc /= SQLITE_DONE) print '("sqlite3_step(): failed")'

        ! Delete the statement.
        rc = sqlite3_finalize(stmt)
    end subroutine insert_row

    subroutine delete_row(db,rc, stmt, user_name,item_name, item_location, lost_date)
        type(c_ptr), intent(inout) :: db
        type(c_ptr), intent(inout) :: stmt
        integer, intent(inout) :: rc
        character(len=*), intent(in) :: user_name
        character(len=*), intent(in) :: item_name
        character(len=*), intent(in) :: item_location
        character(len=*), intent(in) :: lost_date
        ! Create a prepared statement.
        rc = sqlite3_prepare(db, "DELETE FROM lafItems WHERE " // & 
                                    "user_name = ? AND " // &
                                    "item_name = ? AND " // &
                                    "item_location = ? AND " // &
                                    "lost_date = ?", stmt)

        ! Bind the values to the statement.
        rc = sqlite3_bind_text(stmt, 1, user_name)
        rc = sqlite3_bind_text(stmt, 2, item_name)
        rc = sqlite3_bind_text(stmt, 3, item_location)
        rc = sqlite3_bind_text(stmt, 4, lost_date)

        ! Run the statement.
        rc = sqlite3_step(stmt)
        if (rc /= SQLITE_DONE) print '("sqlite3_step(): failed")'

        ! Delete the statement.
        rc = sqlite3_finalize(stmt)
    end subroutine delete_row

    subroutine print_values(stmt, ncols, row_json)
        type(c_ptr), intent(inout) :: stmt
        integer,     intent(in)    :: ncols
        integer                    :: col_type
        integer                    :: i
        character(len=:), allocatable :: key
        character(len=:), allocatable :: current_val
        character(len=:), allocatable, intent(inout) :: row_json
        character(len=15) reward_price_string
        row_json = "{"

        do i = 0, ncols - 1
            col_type = sqlite3_column_type(stmt, i)
            select case (i)
                case(0)
                    continue
                case (1)
                    key = '"user_name":"'
                    current_val = sqlite3_column_text(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(current_val) // trim('",')
                case (2)
                    key = '"item_name":"'
                    current_val = sqlite3_column_text(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(current_val) // trim('",')
                case(3)
                    key = '"item_description":"'
                    current_val = sqlite3_column_text(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(current_val) // trim('",')
                case(4)
                    key = '"item_location":"'
                    current_val = sqlite3_column_text(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(current_val) // trim('",')
                case(5)
                    key = '"item_images":"'
                    current_val = sqlite3_column_text(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(current_val) // trim('",')
                case(6)
                    key = '"lost_location":"'
                    current_val = sqlite3_column_text(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(current_val) // trim('",')
                case(7)
                    key = '"reward_prise""'
                    write(reward_price_string, '(f15.3)') sqlite3_column_double(stmt, i)
                    row_json = trim(row_json) // trim(key) // trim(adjustl(reward_price_string)) 
                case default
                    key = '"undefined":""'
                    row_json = trim(row_json) // trim(key) 
            end select
        end do
        row_json = trim(row_json) // "}"
        ! Print *, row_json
    end subroutine print_values
end module sql_atlnts