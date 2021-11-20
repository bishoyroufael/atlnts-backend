program atlnts_api

    use fcgi_protocol
    use sql_atlnts
    use, intrinsic :: iso_c_binding 
    implicit none

    type(DICT_STRUCT), pointer  :: dict => null() ! Initialisation is important!
    logical                     :: stopped = .false. ! set to true in respond() to terminate program
    integer                     :: unitNo ! unit number  for a scratch file

    character(len=:), allocatable    :: json_o
    
    ! sql vars
    type(c_ptr)                       :: db
    integer                           :: rc
    type(c_ptr)                       :: stmt
    
    real(8)                           :: rwd_pc
    rwd_pc = 1.5
    
    ! create database
    call create_db(db, rc)
    ! call insert_row(db, rc, stmt, 'usernamea','iphone5', 'test','test','test','test', rwd_pc) 
    
    call get_all_lafi_json(db, rc, stmt, json_o)
    ! print *, json_o 

    ! call get_all_lafi_json(db, rc, stmt, json_str)
    ! Print*, json_str
    
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

    ! webserver will return an error since this process will now terminate
    unitNo = fcgip_accept_environment_variables()


contains
    subroutine respond ( dict, unitNo, stopped)

        type(DICT_STRUCT), pointer        :: dict
        integer, intent(in)               :: unitNo
        logical, intent(out)              :: stopped
        
        ! the script name
        character(len=80)  :: scriptName
        

        ! retrieve script name (key=DOCUMENT_URI) from dictionary
        call cgi_get( dict, "DOCUMENT_URI", scriptName )
        select case (trim(scriptName))
            
            case('/api/v1/get_laf_items')
                write(unitNo, AFORMAT) json_o 

            case('/api/v1/add_laf_item')
                write(unitNo, AFORMAT) '{"test":"test"}'

            case('/api/v1/del_laf_item')
                write(unitNo, AFORMAT) '{"test":"test"}'
            
            case ('/api/v1/shutdown') ! to terminate program
                write(unitNo,AFORMAT) '{"shutdown":"true"}'
                stopped = .true.

        end select

        return

    end subroutine respond

end program atlnts_api