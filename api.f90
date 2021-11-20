program atlnts_api
    use fcgi_protocol
    use :: sqlite
    use sql_atlnts
    use, intrinsic :: iso_c_binding 
    implicit none

    type(DICT_STRUCT), pointer  :: dict => null() ! Initialisation is important!
    logical                     :: stopped = .false. ! set to true in respond() to terminate program
    integer                     :: unitNo ! unit number  for a scratch file

    
    ! sql vars
    type(c_ptr)                       :: db
    integer                           :: rc
    type(c_ptr)                       :: stmt
    character(len=:), allocatable    :: json_o
    
    ! create database
    call create_db(db, rc)
    ! call get_all_lafi_json(db,rc,stmt,json_o)
    ! print*, json_o
    
    ! open scratch file
    open(newunit=unitNo, status='scratch')
    ! comment previous line AND uncomment next line for debugging;
    ! open(newunit=unitNo, file='fcgiout', status='unknown') ! file 'fcgiout' will show %REMARKS%

    ! wait for environment variables from webserver
    do while (fcgip_accept_environment_variables() >= 0)

        ! build dictionary from GET or POST data, environment variables
        call fcgip_make_dictionary( dict, unitNo )

        ! give dictionary to the user supplied routine
        ! routine writes the response to unitNo
        ! routine sets stopped to true to terminate program
        call respond(dict, unitNo, stopped)

        ! copy file unitNo to the webserver
        call fcgip_put_file( unitNo, 'application/json' )

        ! terminate?
        if (stopped) exit

    end do !  while (fcgip_accept_environment_variables() >= 0)

    ! before termination, it is good practice to close files that are open
    close(unitNo)
    rc = sqlite3_close(db)
    ! webserver will return an error since this process will now terminate
    unitNo = fcgip_accept_environment_variables()


contains
    subroutine respond ( dict, unitNo, stopped)

        type(DICT_STRUCT), pointer        :: dict
        integer, intent(in)               :: unitNo
        logical, intent(out)              :: stopped
        logical                           :: ok_inputs
        character(len=10):: arg
        character(len=32) :: user_name
        character(len=128) :: item_name 
        character(len=65563) :: item_description
        character(len=128) :: item_location
        character(len=256) :: item_images
        character(len=64) :: lost_date
        character(len=32) :: reward_price

        ! the script name
        character(len=80)  :: scriptName
        

        ! retrieve script name (key=DOCUMENT_URI) from dictionary
        call cgi_get( dict, "DOCUMENT_URI", scriptName )
        select case (trim(scriptName))
            case('/api/v1/test')
                write(unitNo, AFORMAT) 'API Alive!'

            case('/api/v1/get_laf_items')
                call get_all_lafi_json(db,rc,stmt,json_o)
                write(unitNo, AFORMAT) trim(json_o)
            
            case('/api/v1/add_laf_item')
                arg = '?'
                call cgi_get( dict, "arg", arg)
                call cgi_get( dict, "user_name", user_name)
                call cgi_get( dict, "item_name", item_name)
                call cgi_get( dict, "item_description", item_description)
                call cgi_get( dict, "item_location", item_location)
                call cgi_get( dict, "item_images", item_images)
                call cgi_get( dict, "lost_date", lost_date)
                call cgi_get( dict, "reward_price", reward_price)
                
                call insert_row(db,rc,stmt, trim(adjustl(user_name)), &
                                            trim(adjustl(item_name)), &
                                            trim(adjustl(item_description)), & 
                                            trim(adjustl(item_location)), &
                                            trim(adjustl(item_images)), &
                                            trim(adjustl(lost_date)), &
                                            trim(adjustl(reward_price)), &
                                            json_o)
                ! call insert_row(db,rc,stmt, )
                write(unitNo, AFORMAT) json_o 

            case('/api/v1/get_user_laf_items')
                arg = '?'
                call cgi_get( dict, "arg", arg)
                call cgi_get( dict, "user_name", user_name)
                call get_user_lafi_json(db,rc,stmt, trim(adjustl(user_name)), json_o)
                write(unitNo, AFORMAT) json_o


            case('/api/v1/del_laf_item')
                call cgi_get( dict, "arg", arg)
                call cgi_get( dict, "user_name", user_name)
                call cgi_get( dict, "item_name", item_name)
                call cgi_get( dict, "item_location", item_location)
                call cgi_get( dict, "lost_date", lost_date)
                call delete_row(db,&
                                rc,&
                                stmt,&
                                trim(adjustl(user_name)),&
                                trim(adjustl(item_name)),&
                                trim(adjustl(item_location)),&
                                trim(adjustl(lost_date)),&
                                json_o)
                write(unitNo, AFORMAT) json_o 
            
            case ('/api/v1/shutdown') ! to terminate program
                write(unitNo,AFORMAT) '{"shutdown":"true"}'
                stopped = .true.

        end select

        return

    end subroutine respond

end program atlnts_api